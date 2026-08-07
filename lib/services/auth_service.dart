import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

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

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_districtKey);
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
