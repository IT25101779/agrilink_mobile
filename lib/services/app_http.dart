import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_settings.dart';
import 'session_events.dart';

/// Thin wrapper around package:http that:
///   1. Adds the header ngrok requires to skip its free-tier browser-warning
///      interstitial page (harmless to keep even on permanent hosting like
///      Vercel — the extra header is simply ignored by non-ngrok servers).
///   2. Adds a 20-second timeout to every request.
///   3. Catches ANY network-level exception (timeout, DNS failure, no
///      internet, TLS error, server cold-start taking too long, etc.) and
///      converts it into a normal-looking error response instead of letting
///      it throw uncaught.
///
/// That last point fixes a real bug: without this, a screen's "Register" or
/// "Login" button could spin forever if the network call itself failed,
/// because the calling code's `setState(() => _isLoading = false)` would
/// never be reached — the exception happened before that line ran. Now
/// every screen always gets back a proper `{"success": false, "message":
/// "..."}` response it already knows how to handle, so the spinner always
/// resolves and the person sees a clear error instead of a frozen screen.
class AppHttp {
  static const Map<String, String> _ngrokBypass = {"ngrok-skip-browser-warning": "true"};
  static const Duration _timeout = Duration(seconds: 20);


  /// A 401 on a request that CARRIED a login token means the token has expired
  /// (or the account was removed). Tell the app so it can sign out cleanly
  /// instead of leaving the farmer on half-working screens.
  static http.Response _checkSession(http.Response response, Map<String, String>? headers) {
    AppSettings.instance.addBytes(response.bodyBytes.length); // running data counter (Profile -> Settings)
    if (response.statusCode == 401 && headers != null && headers.keys.any((k) => k.toLowerCase() == "authorization")) {
      SessionEvents.notifyExpired();
    }
    return response;
  }


  /// Every request carries the login token automatically, so screens never have to remember to.
  /// (Login / register / password-reset calls are left alone.)
  static Future<Map<String, String>?> _withAuth(Uri url, Map<String, String>? headers) async {
    final path = url.path;
    if (path.contains("/auth/login") || path.contains("/auth/register") || path.contains("/auth/forgot") || path.contains("/auth/reset")) return headers;
    if (headers != null && headers.keys.any((k) => k.toLowerCase() == "authorization")) return headers;
    try {
      final token = (await SharedPreferences.getInstance()).getString("auth_token");
      if (token == null || token.isEmpty) return headers;
      return {...?headers, "Authorization": "Bearer $token"};
    } catch (_) {
      return headers;
    }
  }

  static http.Response _networkErrorResponse(Object error) {
    final message = error.toString().contains("TimeoutException")
        ? "The server took too long to respond. Please check your internet connection and try again."
        : "Could not reach the server. Please check your internet connection and try again.";
    return http.Response(
      jsonEncode({"success": false, "message": message}),
      599,
    );
  }

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    try {
      headers = await _withAuth(url, headers);
      return _checkSession(await http.get(url, headers: {..._ngrokBypass, ...?headers}).timeout(_timeout), headers);
    } catch (e) {
      return _networkErrorResponse(e);
    }
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    try {
      headers = await _withAuth(url, headers);
      return _checkSession(await http.post(url, headers: {..._ngrokBypass, ...?headers}, body: body).timeout(_timeout), headers);
    } catch (e) {
      return _networkErrorResponse(e);
    }
  }

  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) async {
    try {
      headers = await _withAuth(url, headers);
      return _checkSession(await http.put(url, headers: {..._ngrokBypass, ...?headers}, body: body).timeout(_timeout), headers);
    } catch (e) {
      return _networkErrorResponse(e);
    }
  }

  static Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body}) async {
    try {
      headers = await _withAuth(url, headers);
      return _checkSession(await http.patch(url, headers: {..._ngrokBypass, ...?headers}, body: body).timeout(_timeout), headers);
    } catch (e) {
      return _networkErrorResponse(e);
    }
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    try {
      headers = await _withAuth(url, headers);
      return _checkSession(await http.delete(url, headers: {..._ngrokBypass, ...?headers}).timeout(_timeout), headers);
    } catch (e) {
      return _networkErrorResponse(e);
    }
  }
}