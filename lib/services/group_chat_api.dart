import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'app_http.dart';
import 'auth_service.dart';

/// All calls for the farmer group chat. The server works out who you are from
/// your login token — the app never sends a user id.
class GroupChatApi {
  static String get _base => "${ApiService.baseUrl}/group-chat";

  static Future<Map<String, String>> _headers({bool json = false}) async {
    final token = await AuthService.getToken();
    return {
      if (json) "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  static Map<String, dynamic> _handle(http.Response response) {
    try {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      return {"success": false, "message": "Server returned an unexpected response (status ${response.statusCode})."};
    }
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final response = await AppHttp.get(Uri.parse("$_base$path"), headers: await _headers());
    return _handle(response);
  }

  static Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await AppHttp.post(Uri.parse("$_base$path"), headers: await _headers(json: true), body: jsonEncode(body));
    return _handle(response);
  }

  // ---- groups ----
  static Future<Map<String, dynamic>> myGroups() => _get("/groups");
  static Future<Map<String, dynamic>> suggested() => _get("/groups/suggested");

  static Future<Map<String, dynamic>> search({String? district, String? crop}) {
    final query = <String>[
      if (district != null && district.isNotEmpty) "district=${Uri.encodeQueryComponent(district)}",
      if (crop != null && crop.isNotEmpty) "crop=${Uri.encodeQueryComponent(crop)}",
    ].join("&");
    return _get("/groups/search${query.isEmpty ? "" : "?$query"}");
  }

  static Future<Map<String, dynamic>> join(String groupKey) => _post("/groups/join", {"groupKey": groupKey});
  static Future<Map<String, dynamic>> leave(String groupKey) => _post("/groups/leave", {"groupKey": groupKey});
  static Future<Map<String, dynamic>> mute(String groupKey, bool muted) => _post("/groups/mute", {"groupKey": groupKey, "muted": muted});
  static Future<Map<String, dynamic>> block(String groupKey, String alias) => _post("/groups/block", {"groupKey": groupKey, "alias": alias, "blocked": true});

  // ---- messages ----
  static Future<Map<String, dynamic>> messages(String groupKey, {String? after, String? before, int limit = 40}) {
    final query = "groupKey=${Uri.encodeQueryComponent(groupKey)}&limit=$limit"
        "${after != null ? "&after=$after" : ""}${before != null ? "&before=$before" : ""}";
    return _get("/messages?$query");
  }

  static Future<Map<String, dynamic>> send({
    required String groupKey,
    String type = "text",
    String text = "",
    String? imageBase64,
    String? voiceBase64,
    int? durationSec,
    String? replyToId,
  }) {
    return _post("/messages", {
      "groupKey": groupKey,
      "type": type,
      "text": text,
      if (imageBase64 != null) "imageBase64": imageBase64,
      if (voiceBase64 != null) "voiceBase64": voiceBase64,
      if (durationSec != null) "durationSec": durationSec,
      if (replyToId != null) "replyToId": replyToId,
    });
  }

  static Future<Map<String, dynamic>> helpful(String messageId) => _post("/messages/helpful", {"messageId": messageId});
  static Future<Map<String, dynamic>> report(String messageId, String reason) => _post("/messages/report", {"messageId": messageId, "reason": reason});
  static Future<Map<String, dynamic>> deleteMessage(String messageId) => _post("/messages/delete", {"messageId": messageId});
  static Future<Map<String, dynamic>> translate(String messageId, String target) => _post("/messages/translate", {"messageId": messageId, "target": target});

  // ---- photos and voice notes (private: needs the login token) ----
  static final Map<String, Uint8List> _mediaCache = {};

  static Future<Uint8List?> mediaBytes(String mediaId) async {
    final cached = _mediaCache[mediaId];
    if (cached != null) return cached;
    final response = await AppHttp.get(Uri.parse("$_base/media/$mediaId"), headers: await _headers());
    if (response.statusCode != 200) return null;
    if (_mediaCache.length > 40) _mediaCache.remove(_mediaCache.keys.first); // keep memory small
    _mediaCache[mediaId] = response.bodyBytes;
    return response.bodyBytes;
  }
}
