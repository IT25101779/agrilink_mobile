import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'app_http.dart';
import 'auth_service.dart';

/// API calls for the newer features: Oversupply Guard, price forecast,
/// Sell-or-Hold advice, Group Lots, Buyer Requests and the Farm Passport.
///
/// Unlike some older calls, these all send the farmer's login token, and the
/// server works out who is asking from that token — never from anything the
/// app sends in the request body.
class InsightsApi {
  static String get _base => ApiService.baseUrl;

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
      return {
        "success": false,
        "message": "Server returned an unexpected response (status ${response.statusCode}).",
      };
    }
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final response = await AppHttp.get(Uri.parse("$_base$path"), headers: await _headers());
    return _handle(response);
  }

  static Future<Map<String, dynamic>> _post(String path, [Map<String, dynamic>? body]) async {
    final response = await AppHttp.post(
      Uri.parse("$_base$path"),
      headers: await _headers(json: true),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _handle(response);
  }

  // ---------------- Oversupply Guard ----------------

  static Future<Map<String, dynamic>> getPlantingSignals({String? district}) {
    final query = (district != null && district.isNotEmpty) ? "?district=${Uri.encodeQueryComponent(district)}" : "";
    return _get("/insights/planting-signals$query");
  }

  // ---------------- Price forecast + Sell-or-Hold ----------------

  static Future<Map<String, dynamic>> getPriceForecast(String cropType, {int weeks = 12}) {
    return _get("/insights/price-forecast/${Uri.encodeComponent(cropType)}?weeks=$weeks");
  }

  static Future<Map<String, dynamic>> getSellOrHold() => _get("/insights/sell-or-hold");

  /// PROFIT PLANNER. Any of the three optional numbers replaces the typical
  /// planning figure the server would otherwise use.
  static Future<Map<String, dynamic>> getProfitPlan(
    String cropType, {
    double acres = 1,
    double? yieldKgPerAcre,
    double? costPerAcre,
    double? pricePerKg,
  }) {
    final params = <String>["acres=$acres"];
    if (yieldKgPerAcre != null) params.add("yieldKgPerAcre=$yieldKgPerAcre");
    if (costPerAcre != null) params.add("costPerAcre=$costPerAcre");
    if (pricePerKg != null) params.add("pricePerKg=$pricePerKg");
    return _get("/insights/profit-plan/${Uri.encodeComponent(cropType)}?${params.join("&")}");
  }

  static Future<Map<String, dynamic>> generatePriceAlerts() => _post("/insights/price-alerts/generate");

  /// The farmer's own listings — each one includes its live Freshness Clock.
  static Future<Map<String, dynamic>> getMyListings(String farmerId) {
    return _get("/marketplace/listings?farmer=${Uri.encodeQueryComponent(farmerId)}");
  }

  // ---------------- Group lots ----------------

  static Future<Map<String, dynamic>> listLots({String? district, bool mine = false}) {
    final params = <String>[];
    if (mine) {
      params.add("mine=true");
      params.add("status=all");
    } else if (district != null && district.isNotEmpty) {
      params.add("district=${Uri.encodeQueryComponent(district)}");
    }
    final query = params.isEmpty ? "" : "?${params.join("&")}";
    return _get("/group-lots$query");
  }

  static Future<Map<String, dynamic>> createLot({
    required String cropType,
    required double targetKg,
    required double pricePerKg,
    required double quantityKg,
    required int closesInDays,
    String pickupNote = "",
  }) {
    return _post("/group-lots", {
      "cropType": cropType,
      "targetKg": targetKg,
      "pricePerKg": pricePerKg,
      "quantityKg": quantityKg,
      "closesInDays": closesInDays,
      "pickupNote": pickupNote,
    });
  }

  static Future<Map<String, dynamic>> joinLot(String lotId, double quantityKg) {
    return _post("/group-lots/$lotId/join", {"quantityKg": quantityKg});
  }

  static Future<Map<String, dynamic>> leaveLot(String lotId) => _post("/group-lots/$lotId/leave");

  static Future<Map<String, dynamic>> cancelLot(String lotId) => _post("/group-lots/$lotId/cancel");

  // ---------------- Buyer requests (demand board) ----------------

  static Future<Map<String, dynamic>> listDemandRequests({String? district}) {
    final query = (district != null && district.isNotEmpty) ? "?district=${Uri.encodeQueryComponent(district)}" : "";
    return _get("/demand$query");
  }

  static Future<Map<String, dynamic>> makeOffer({
    required String requestId,
    required double quantityKg,
    required double pricePerKg,
    String message = "",
  }) {
    return _post("/demand/$requestId/offers", {
      "quantityKg": quantityKg,
      "pricePerKg": pricePerKg,
      "message": message,
    });
  }

  static Future<Map<String, dynamic>> withdrawOffer(String requestId, String offerId) {
    return _post("/demand/$requestId/offers/$offerId/withdraw");
  }

  // ---------------- Farm Passport ----------------

  static Future<Map<String, dynamic>> getMyPassport() => _get("/passport/me");

  static Future<Map<String, dynamic>> rotatePassportLink() => _post("/passport/rotate");
}
