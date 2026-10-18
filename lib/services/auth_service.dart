import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'app_http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_store.dart';
import 'api_service.dart';
import '../models/timeline_model.dart';

class AuthService {
  static const String _tokenKey = "auth_token";
  static const String _userIdKey = "auth_user_id";
  static const String _userNameKey = "auth_user_name";
  static const String _userRoleKey = "auth_user_role";
  static const String _districtKey = "auth_user_district";

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    Map<String, dynamic>? farmerProfile,
    Map<String, dynamic>? driverProfile,
    String referralCode = "",
  }) async {
    final response = await AppHttp.post(
      Uri.parse("${ApiService.baseUrl}/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": fullName,
        "email": email,
        "phone": phone,
        "password": password,
        "role": role,
        if (farmerProfile != null) "farmerProfile": farmerProfile,
        if (driverProfile != null) "driverProfile": driverProfile,
        if (referralCode.isNotEmpty) "referralCode": referralCode,
      }),
    );
    final result = _handle(response);
    if (result["success"] == true) {
      await _saveSession(result["data"]);
      final district = farmerProfile?["district"] as String?;
      if (district != null && district.trim().isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_districtKey, district.trim());
      }
    }
    return result;
  }

  /// Step 1 of registration: validates the details and emails a 6-digit code.
  /// Nothing is created yet — the account only exists once [registerVerify] confirms the code.
  static Future<Map<String, dynamic>> registerStart({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
    Map<String, dynamic>? farmerProfile,
    Map<String, dynamic>? driverProfile,
    String referralCode = "",
  }) async {
    final response = await AppHttp.post(
      Uri.parse("${ApiService.baseUrl}/auth/register-start"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fullName": fullName,
        "email": email,
        "phone": phone,
        "password": password,
        "role": role,
        if (farmerProfile != null) "farmerProfile": farmerProfile,
        if (driverProfile != null) "driverProfile": driverProfile,
        if (referralCode.isNotEmpty) "referralCode": referralCode,
      }),
    );
    return _handle(response);
  }

  /// Step 2 of registration: confirms the code and actually creates the account.
  /// A driver account is created in "pending" state — the token returned here lets
  /// that same session complete the mandatory profile photo + document upload,
  /// but any LATER login is blocked until an admin approves (see [login]).
  static Future<Map<String, dynamic>> registerVerify({
    required String email,
    required String otp,
  }) async {
    final response = await AppHttp.post(
      Uri.parse("${ApiService.baseUrl}/auth/register-verify"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );
    final result = _handle(response);
    if (result["success"] == true) {
      await _saveSession(result["data"]);
      final district = result["data"]?["user"]?["farmerProfile"]?["district"] as String?;
      if (district != null && district.trim().isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_districtKey, district.trim());
      }
    }
    return result;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await AppHttp.post(
      Uri.parse("${ApiService.baseUrl}/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );
    final result = _handle(response);
    if (result["success"] == true) {
      await _saveSession(result["data"]);
      final district = result["data"]?["user"]?["farmerProfile"]?["district"] as String?;
      if (district != null && district.trim().isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_districtKey, district.trim());
      }
    }
    return result;
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await AppHttp.post(
      Uri.parse("${ApiService.baseUrl}/auth/forgot-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    return _handle(response);
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await AppHttp.post(
      Uri.parse("${ApiService.baseUrl}/auth/reset-password"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp, "newPassword": newPassword}),
    );
    return _handle(response);
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, data["token"]);
    await prefs.setString(_userIdKey, data["user"]["id"]);
    await prefs.setString(_userNameKey, data["user"]["fullName"]);
    await prefs.setString(_userRoleKey, data["user"]["role"]);
  }

  /// BUG FIX (Oct 2026): logout used to clear only SharedPreferences and
  /// OfflineStore's cache/queue — it never touched the Hive "timelines" box,
  /// which is a single box shared by every account that ever logs in on
  /// this phone. That's why switching accounts kept showing the PREVIOUS
  /// farmer's timelines: their records were still sitting in the box.
  /// We now wipe that box too on every logout, so the next person who logs
  /// in on this device starts from a clean slate (their own data gets
  /// pulled back down fresh from the server by pullRemoteTimelines()).
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_districtKey);
    await OfflineStore.clearAll(); // saved copies and waiting records belong to the person who just left
    try {
      if (Hive.isBoxOpen("timelines")) {
        await Hive.box<TimelineModel>("timelines").clear();
      }
    } catch (_) {
      // If the box isn't open for some reason, there's nothing to clear.
    }
  }

  /// After the farmer edits their profile, keep the values stored on the phone in step.
  static Future<void> updateLocalProfile({String? name, String? district}) async {
    final prefs = await SharedPreferences.getInstance();
    if (name != null && name.isNotEmpty) await prefs.setString(_userNameKey, name);
    if (district != null && district.isNotEmpty) await prefs.setString(_districtKey, district);
  }

  static Future<String?> getDistrict() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_districtKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey) != null;
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Map<String, dynamic> _handle(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {"success": false, "message": "Server returned an unexpected response (status ${response.statusCode})."};
    }
  }
}
