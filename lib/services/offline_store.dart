import 'dart:convert';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'app_http.dart';

/// Makes the app usable with a weak or missing connection.
///  - Reads: every successful GET is remembered on the phone. With no internet the last copy is shown
///    (the answer carries "cached": true so a screen can say "showing saved data").
///  - Writes: a few "small record" saves (ledger, price report, harvest, subsidy, wildlife, feedback) are put
///    in a waiting list when there is no internet and sent automatically later. Each one carries a clientId,
///    so the server saves it only once even if the phone retries.
/// Everything here is wiped on logout, so the next person on the phone never sees it.
class OfflineStore {
  static const _cachePrefix = "cache:";
  static const _queueKey = "offline_queue_v1";
  static bool _flushing = false;
  static bool _listening = false;

  static String newId() => "${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}";

  static Future<Map<String, dynamic>> cachedGet(String path, Future<http.Response> Function() fetch, Map<String, dynamic> Function(http.Response) handle) async {
    final r = await fetch();
    final prefs = await SharedPreferences.getInstance();
    if (r.statusCode == 599) {
      final raw = prefs.getString("$_cachePrefix$path");
      if (raw != null) {
        try {
          final m = Map<String, dynamic>.from(jsonDecode(raw) as Map);
          m["cached"] = true;
          return m;
        } catch (_) {}
      }
      return handle(r);
    }
    final m = handle(r);
    if (m["success"] == true) {
      m["cachedAt"] = DateTime.now().toIso8601String();
      await prefs.setString("$_cachePrefix$path", jsonEncode(m));
    }
    return m;
  }

  /// Sends now; if there is no internet, saves it to send later.
  static Future<Map<String, dynamic>> postOrQueue(String path, Map<String, dynamic> body, String label, Map<String, dynamic> Function(http.Response) handle) async {
    final withId = {...body, "clientId": body["clientId"] ?? newId()};
    final r = await AppHttp.post(Uri.parse("${ApiService.baseUrl}$path"), headers: {"Content-Type": "application/json"}, body: jsonEncode(withId));
    if (r.statusCode == 599) {
      await _enqueue(path, withId, label);
      return {"success": true, "queued": true, "message": "No internet. Saved on your phone - it will be sent automatically."};
    }
    return handle(r);
  }

  static Future<List<Map<String, dynamic>>> _load(SharedPreferences prefs) async {
    try {
      return (jsonDecode(prefs.getString(_queueKey) ?? "[]") as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _enqueue(String path, Map<String, dynamic> body, String label) async {
    final prefs = await SharedPreferences.getInstance();
    final q = await _load(prefs);
    q.add({"path": path, "body": body, "label": label, "attempts": 0, "at": DateTime.now().toIso8601String()});
    await prefs.setString(_queueKey, jsonEncode(q.length > 200 ? q.sublist(q.length - 200) : q));
  }

  static Future<int> pendingCount() async => (await _load(await SharedPreferences.getInstance())).length;

  /// Sends what is waiting. Stops at the first "no internet". A record the server refuses (4xx) is dropped;
  /// a server hiccup (5xx) is retried up to 5 times.
  static Future<int> flush() async {
    if (_flushing) return 0;
    _flushing = true;
    var sent = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final q = await _load(prefs);
      final keep = <Map<String, dynamic>>[];
      var offline = false;
      for (final item in q) {
        if (offline) {
          keep.add(item);
          continue;
        }
        final r = await AppHttp.post(Uri.parse("${ApiService.baseUrl}${item["path"]}"), headers: {"Content-Type": "application/json"}, body: jsonEncode(item["body"]));
        if (r.statusCode == 599) {
          offline = true;
          keep.add(item);
        } else if (r.statusCode >= 200 && r.statusCode < 300) {
          sent++;
        } else if (r.statusCode >= 500) {
          item["attempts"] = (item["attempts"] as int? ?? 0) + 1;
          if ((item["attempts"] as int) < 5) keep.add(item);
        } // 4xx: refused by the server - drop it
      }
      await prefs.setString(_queueKey, jsonEncode(keep));
    } finally {
      _flushing = false;
    }
    return sent;
  }

  /// Call once at start: sends the waiting list whenever the internet comes back.
  static void startListening() {
    if (_listening) return;
    _listening = true;
    Connectivity().onConnectivityChanged.listen((results) {
      if (!results.contains(ConnectivityResult.none)) flush();
    });
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys().where((k) => k.startsWith(_cachePrefix) || k == _queueKey).toList()) {
      await prefs.remove(k);
    }
  }
}
