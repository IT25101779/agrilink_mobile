import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'app_http.dart';
import 'offline_store.dart';

/// Wildlife alerts, offices, officer questions, harvest + subsidy records, damage reports, rain planner,
/// disputes / photos / reports / blocks, feedback, verification, payment details and privacy tools.
/// The login token is attached by AppHttp.
class HelpApi {
  static String get _base => ApiService.baseUrl;

  static Map<String, dynamic> _handle(http.Response r) {
    try {
      return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {
      return {"success": false, "message": "Server returned an unexpected response (status ${r.statusCode})."};
    }
  }

  static const _json = {"Content-Type": "application/json"};
  static Future<Map<String, dynamic>> _get(String path) => OfflineStore.cachedGet(path, () => AppHttp.get(Uri.parse("$_base$path")), _handle);
  static Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async => _handle(await AppHttp.post(Uri.parse("$_base$path"), headers: _json, body: jsonEncode(body ?? {})));
  static Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async => _handle(await AppHttp.put(Uri.parse("$_base$path"), headers: _json, body: jsonEncode(body)));
  static Future<Map<String, dynamic>> _delete(String path) async => _handle(await AppHttp.delete(Uri.parse("$_base$path")));
  static Future<Map<String, dynamic>> _queued(String path, Map<String, dynamic> body, String label) => OfflineStore.postOrQueue(path, body, label, _handle);

  // ---- wildlife ----
  static Future<Map<String, dynamic>> reportWildlife(String species, double lat, double lng, String note) => _queued("/help/wildlife", {"species": species, "latitude": lat, "longitude": lng, "note": note}, "wildlife");
  static Future<Map<String, dynamic>> nearbyWildlife(double lat, double lng) => _get("/help/wildlife/nearby?latitude=$lat&longitude=$lng&radiusKm=12");
  static Future<Map<String, dynamic>> confirmWildlife(String id, String kind) => _post("/help/wildlife/$id/confirm", {"kind": kind});

  // ---- help ----
  static Future<Map<String, dynamic>> offices({String? district}) => _get("/help/offices${district == null || district.isEmpty ? "" : "?district=${Uri.encodeQueryComponent(district)}"}");
  static Future<Map<String, dynamic>> askQuestion(String crop, String text) => _post("/help/questions", {"cropType": crop, "text": text});
  static Future<Map<String, dynamic>> myQuestions() => _get("/help/questions/mine");
  static Future<Map<String, dynamic>> officerOverview() => _get("/help/officer/overview");
  static Future<Map<String, dynamic>> answerQuestion(String id, String answer) => _post("/help/officer/questions/$id/answer", {"answer": answer});

  // ---- records ----
  static Future<Map<String, dynamic>> yields() => _get("/records/yields");
  static Future<Map<String, dynamic>> addYield(Map<String, dynamic> body) => _queued("/records/yields", body, "harvest");
  static Future<Map<String, dynamic>> deleteYield(String id) => _delete("/records/yields/$id");
  static Future<Map<String, dynamic>> subsidies() => _get("/records/subsidies");
  static Future<Map<String, dynamic>> addSubsidy(Map<String, dynamic> body) => _queued("/records/subsidies", body, "subsidy");
  static Future<Map<String, dynamic>> deleteSubsidy(String id) => _delete("/records/subsidies/$id");
  static Future<Map<String, dynamic>> supportPrices() => _get("/records/support-prices");
  static Future<Map<String, dynamic>> priceCheck(String crop, double price) => _post("/records/price-check", {"cropType": crop, "pricePerKg": price});
  static Future<Map<String, dynamic>> damageList() => _get("/records/damage");
  static Future<Map<String, dynamic>> addDamage(Map<String, dynamic> body) => _post("/records/damage", body);
  static Future<Map<String, dynamic>> rainPlanner({String? district}) => _get("/records/rain-planner${district == null || district.isEmpty ? "" : "?district=${Uri.encodeQueryComponent(district)}"}");
  static Future<Map<String, dynamic>> reportLink(String kind, {String? damageId}) => _post("/records/report-link/$kind", {if (damageId != null) "damageId": damageId});

  // ---- order safety ----
  static Future<Map<String, dynamic>> addOrderPhoto(String orderId, String base64, String label) => _post("/orders/$orderId/photos", {"imageBase64": base64, "label": label});
  static Future<Map<String, dynamic>> orderPhotos(String orderId) => _get("/orders/$orderId/photos");
  static Future<Map<String, dynamic>> openDispute(String orderId, String reason, String description) => _post("/orders/$orderId/dispute", {"reason": reason, "description": description});
  static Future<Map<String, dynamic>> myDisputes() => _get("/disputes/mine");
  static Future<Map<String, dynamic>> disputeMessage(String id, String text) => _post("/disputes/$id/message", {"text": text});
  static Future<Map<String, dynamic>> reportUser(String userId, String reason, {String context = "order", String contextId = "", String note = ""}) => _post("/reports", {"reportedId": userId, "reason": reason, "context": context, "contextId": contextId, "note": note});
  static Future<Map<String, dynamic>> blockUser(String userId) => _post("/blocks", {"userId": userId});
  static Future<Map<String, dynamic>> unblockUser(String userId) => _delete("/blocks/$userId");
  static Future<Map<String, dynamic>> myBlocks() => _get("/blocks");
  static String photoUrl(String id) => "$_base/photos/$id";

  // ---- feedback / verification / payment / privacy ----
  static Future<Map<String, dynamic>> feedback(String kind, String message, String screen) => _queued("/feedback", {"kind": kind, "message": message, "screen": screen, "appVersion": "1.1.0"}, "feedback");
  static Future<Map<String, dynamic>> submitVerification(String docType, String base64) => _post("/auth/verification", {"docType": docType, "imageBase64": base64});
  static Future<Map<String, dynamic>> getPayment() => _get("/auth/me/payment");
  static Future<Map<String, dynamic>> setPayment(String instructions) => _put("/auth/me/payment", {"instructions": instructions});
  static Future<Map<String, dynamic>> setPaymentQr(String base64) => _put("/auth/me/payment/qr", {"imageBase64": base64});
  static Future<Map<String, dynamic>> removePaymentQr() => _delete("/auth/me/payment/qr");
  static Future<Map<String, dynamic>> consent() => _post("/auth/consent", {"version": "2026-09"});
  static Future<Map<String, dynamic>> referrals() => _get("/auth/referrals");
  static Future<Map<String, dynamic>> deleteAccount(String password) => _post("/auth/delete-account", {"password": password});
  static Future<String> exportData() async => (await AppHttp.get(Uri.parse("$_base/auth/export"))).body;
  static Future<Map<String, dynamic>> appVersion() async => _handle(await AppHttp.get(Uri.parse("$_base/app/version")));
  static String get privacyUrl => "$_base/legal/privacy";
}
