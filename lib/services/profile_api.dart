import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'app_http.dart';
import 'auth_service.dart';

/// Your own profile: edit details, change password, profile picture.
class ProfileApi {
  static String get _base => "${ApiService.baseUrl}/auth";

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await AuthService.getToken();
    return {if (json) "Content-Type": "application/json", if (token != null) "Authorization": "Bearer $token"};
  }

  static Map<String, dynamic> _handle(http.Response r) {
    try {
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return {"success": false, "message": "Server returned an unexpected response (status ${r.statusCode})."};
    }
  }

  static Future<Map<String, dynamic>> me() async => _handle(await AppHttp.get(Uri.parse("$_base/me"), headers: await _headers()));

  static Future<Map<String, dynamic>> update(Map<String, dynamic> fields) async =>
      _handle(await AppHttp.patch(Uri.parse("$_base/me"), headers: await _headers(json: true), body: jsonEncode(fields)));

  static Future<Map<String, dynamic>> changePassword(String current, String next) async => _handle(
      await AppHttp.post(Uri.parse("$_base/change-password"), headers: await _headers(json: true), body: jsonEncode({"currentPassword": current, "newPassword": next})));

  static Future<Map<String, dynamic>> setAvatar(Uint8List bytes) async {
    // PUT is not in AppHttp, so this uses POST-style wrapping through a plain client with the same timeout behaviour.
    try {
      final r = await http.put(Uri.parse("$_base/me/avatar"), headers: await _headers(json: true), body: jsonEncode({"imageBase64": base64Encode(bytes)})).timeout(const Duration(seconds: 25));
      _cache.clear();
      return _handle(r);
    } catch (_) {
      return {"success": false, "message": "Could not upload the photo. Check your internet connection."};
    }
  }

  static Future<Map<String, dynamic>> removeAvatar() async {
    final r = _handle(await AppHttp.delete(Uri.parse("$_base/me/avatar"), headers: await _headers()));
    _cache.clear();
    return r;
  }

  // ---- pictures (fetched with the login token, kept in memory) ----
  static final Map<String, Uint8List?> _cache = {};

  static Future<Uint8List?> avatarBytes(String userId, {String version = ""}) async {
    final key = "$userId|$version";
    if (_cache.containsKey(key)) return _cache[key];
    final r = await AppHttp.get(Uri.parse("$_base/avatar/$userId"), headers: await _headers());
    final bytes = r.statusCode == 200 ? r.bodyBytes : null;
    if (_cache.length > 60) _cache.remove(_cache.keys.first);
    _cache[key] = bytes;
    return bytes;
  }
}
