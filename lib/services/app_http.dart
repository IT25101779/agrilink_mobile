import 'dart:convert';
import 'package:http/http.dart' as http;

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
      return await http.get(url, headers: {..._ngrokBypass, ...?headers}).timeout(_timeout);
    } catch (e) {
      return _networkErrorResponse(e);
    }
  }

  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    try {
      return await http.post(url, headers: {..._ngrokBypass, ...?headers}, body: body).timeout(_timeout);
    } catch (e) {
      return _networkErrorResponse(e);
    }
  }

  static Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body}) async {
    try {
      return await http.patch(url, headers: {..._ngrokBypass, ...?headers}, body: body).timeout(_timeout);
    } catch (e) {
      return _networkErrorResponse(e);
    }
  }

  static Future<http.Response> delete(Uri url, {Map<String, String>? headers}) async {
    try {
      return await http.delete(url, headers: {..._ngrokBypass, ...?headers}).timeout(_timeout);
    } catch (e) {
      return _networkErrorResponse(e);
    }
  }
}