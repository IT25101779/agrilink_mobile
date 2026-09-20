import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'app_http.dart';
import 'auth_service.dart';
import 'offline_store.dart';

/// Orders, ratings, return trips, farm ledger, price board and surveys.
/// Every call sends the login token — the server decides who you are from it.
class FarmApi {
  static String get _base => ApiService.baseUrl;

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

  static Future<Map<String, dynamic>> _get(String path) => OfflineStore.cachedGet(path, () async => AppHttp.get(Uri.parse("$_base$path"), headers: await _headers()), _handle);

  static Future<Map<String, dynamic>> _queued(String path, Map<String, dynamic> body, String label) => OfflineStore.postOrQueue(path, body, label, _handle);

  static Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async =>
      _handle(await AppHttp.post(Uri.parse("$_base$path"), headers: await _headers(json: true), body: jsonEncode(body ?? <String, dynamic>{})));

  static Future<Map<String, dynamic>> _delete(String path) async => _handle(await AppHttp.delete(Uri.parse("$_base$path"), headers: await _headers()));

  // ---------------- orders & ratings ----------------
  static Future<Map<String, dynamic>> myOrders() => _get("/orders/mine");
  static Future<Map<String, dynamic>> acceptOrder(String id) => _post("/orders/$id/accept");
  static Future<Map<String, dynamic>> cancelOrder(String id, [String reason = ""]) => _post("/orders/$id/cancel", {"reason": reason});
  static Future<Map<String, dynamic>> dispatchOrder(String id, String method) => _post("/orders/$id/dispatch", {"method": method});
  static Future<Map<String, dynamic>> deliverOrder(String id, String code) => _post("/orders/$id/deliver", {"code": code});
  static Future<Map<String, dynamic>> confirmPayment(String id) => _post("/orders/$id/confirm-payment");
  static Future<Map<String, dynamic>> rate(String orderId, int stars, List<String> tags, String comment) => _post("/ratings", {"orderId": orderId, "stars": stars, "tags": tags, "comment": comment});
  static Future<Map<String, dynamic>> ratingsReceived() => _get("/ratings/received");

  // ---------------- delivery freshness & return trips ----------------
  static Future<Map<String, dynamic>> deliveryEstimate({required String cropType, DateTime? harvestDate, String? district}) =>
      _post("/return-trips/estimate", {"cropType": cropType, if (harvestDate != null) "harvestDate": harvestDate.toIso8601String(), if (district != null) "district": district});

  static Future<Map<String, dynamic>> returnTrips({String? district}) => _get("/return-trips${district == null || district.isEmpty ? "" : "?district=${Uri.encodeQueryComponent(district)}"}");
  static Future<Map<String, dynamic>> myTrips() => _get("/return-trips/mine");
  static Future<Map<String, dynamic>> bookTrip(String id, int kg, String crop) => _post("/return-trips/$id/book", {"weightKg": kg, "cropType": crop});
  static Future<Map<String, dynamic>> updateBooking(String tripId, String bookingId, String action) => _post("/return-trips/$tripId/bookings/$bookingId", {"action": action});
  static Future<Map<String, dynamic>> createTrip(Map<String, dynamic> body) => _post("/return-trips", body);
  static Future<Map<String, dynamic>> cancelTrip(String id) => _post("/return-trips/$id/cancel");

  // ---------------- farm ledger ----------------
  static Future<Map<String, dynamic>> ledgerSummary() => _get("/ledger/summary");
  static Future<Map<String, dynamic>> ledgerList({String? cropType}) => _get("/ledger${cropType == null ? "" : "?cropType=${Uri.encodeQueryComponent(cropType)}"}");
  static Future<Map<String, dynamic>> ledgerAdd(Map<String, dynamic> body) => _queued("/ledger", body, "ledger");
  static Future<Map<String, dynamic>> ledgerDelete(String id) => _delete("/ledger/$id");

  // ---------------- price board ----------------
  static Future<Map<String, dynamic>> priceBoard({String? market}) => _get("/prices/board${market == null ? "" : "?market=${Uri.encodeQueryComponent(market)}"}");
  static Future<Map<String, dynamic>> priceHistory(String crop, {String? market}) => _get("/prices/history/${Uri.encodeComponent(crop)}?days=30${market == null ? "" : "&market=${Uri.encodeQueryComponent(market)}"}");
  static Future<Map<String, dynamic>> reportPrice(String crop, String market, double price) => _queued("/prices/report", {"cropType": crop, "market": market, "pricePerKg": price}, "price");
  static Future<Map<String, dynamic>> myAlerts() => _get("/prices/alerts");
  static Future<Map<String, dynamic>> addAlert(String crop, String direction, double threshold, {String market = ""}) => _post("/prices/alerts", {"cropType": crop, "direction": direction, "thresholdLkr": threshold, "market": market});
  static Future<Map<String, dynamic>> deleteAlert(String id) => _delete("/prices/alerts/$id");

  // ---------------- surveys ----------------
  static Future<Map<String, dynamic>> openSurveys() => _get("/surveys/open");
  static Future<Map<String, dynamic>> respondSurvey(String id, Map<String, dynamic> answers) => _post("/surveys/$id/respond", {"answers": answers});

  // ---------------- group chat directory ----------------
  static Future<Map<String, dynamic>> groupDirectory() => _get("/group-chat/groups/directory");
}
