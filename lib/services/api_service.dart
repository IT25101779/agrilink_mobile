import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_http.dart';

/// Central API client for AgriLink AI 2.0.
/// Points to the permanently hosted backend on Vercel.
class ApiService {
  static const String baseUrl = "https://agrilink-backend.vercel.app/api";

  static Future<Map<String, dynamic>> createMarketplaceListing({
    required String farmerId,
    required String cropType,
    required double quantityKg,
    required double pricePerKg,
    required DateTime harvestDate,
    String qualityGrade = "A",
    List<String> photos = const [],
  }) async {
    final response = await AppHttp.post(
      Uri.parse("$baseUrl/marketplace/listings"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "farmer": farmerId,
        "cropType": cropType,
        "quantityKg": quantityKg,
        "pricePerKg": pricePerKg,
        "harvestDate": harvestDate.toIso8601String(),
        "qualityGrade": qualityGrade,
        "photos": photos,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMyListings(String farmerId) async {
    final response = await AppHttp.get(Uri.parse("$baseUrl/marketplace/listings"));
    final result = _handleResponse(response);
    if (result["success"] == true) {
      final allListings = (result["data"] as List);
      final mine = allListings.where((l) => l["farmer"]?["_id"] == farmerId || l["farmer"] == farmerId).toList();
      return {"success": true, "data": mine};
    }
    return result;
  }

  static Future<Map<String, dynamic>> getPricePrediction(String cropType) async {
    final response = await AppHttp.get(Uri.parse("$baseUrl/price-predict/$cropType"));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> scanCropDisease({
    required String farmerId,
    required String cropType,
    required String imageBase64,
    required double latitude,
    required double longitude,
    String? district,
  }) async {
    final response = await AppHttp.post(
      Uri.parse("$baseUrl/disease/scan"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "farmer": farmerId,
        "cropType": cropType,
        "imageBase64": imageBase64,
        "latitude": latitude,
        "longitude": longitude,
        "district": district,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getOutbreakAlerts({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final response = await AppHttp.get(
      Uri.parse("$baseUrl/disease/outbreak-alerts?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm"),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> upsertLorryStatus({
    required String driverId,
    required String vehicleRegistrationNo,
    required double totalCapacityKg,
    double? remainingCapacityKg,
    required String destinationHub,
    required double latitude,
    required double longitude,
    bool isTrackingActive = true,
  }) async {
    final response = await AppHttp.post(
      Uri.parse("$baseUrl/logistics/lorries"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "driver": driverId,
        "vehicleRegistrationNo": vehicleRegistrationNo,
        "totalCapacityKg": totalCapacityKg,
        "remainingCapacityKg": remainingCapacityKg,
        "destinationHub": destinationHub,
        "latitude": latitude,
        "longitude": longitude,
        "isTrackingActive": isTrackingActive,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateLorryLocation({
    required String lorryId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await AppHttp.patch(
      Uri.parse("$baseUrl/logistics/lorries/$lorryId/location"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"latitude": latitude, "longitude": longitude}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> toggleLorryTracking({
    required String lorryId,
    required bool isTrackingActive,
  }) async {
    final response = await AppHttp.patch(
      Uri.parse("$baseUrl/logistics/lorries/$lorryId/toggle-tracking"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"isTrackingActive": isTrackingActive}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMyLorry(String driverId) async {
    final response = await AppHttp.get(Uri.parse("$baseUrl/logistics/lorries/mine?driverId=$driverId"));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getNearbyLorries({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    String? destinationHub,
  }) async {
    final hubParam = destinationHub != null ? "&destinationHub=$destinationHub" : "";
    final response = await AppHttp.get(
      Uri.parse("$baseUrl/logistics/lorries/nearby?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm$hubParam"),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> requestCargoSpace({
    required String lorryId,
    required String farmerId,
    required double weightKg,
    required double latitude,
    required double longitude,
    String? listingRef,
  }) async {
    final response = await AppHttp.post(
      Uri.parse("$baseUrl/logistics/lorries/$lorryId/cargo-request"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "farmer": farmerId,
        "weightKg": weightKg,
        "latitude": latitude,
        "longitude": longitude,
        "listingRef": listingRef,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateCargoBooking({
    required String lorryId,
    required String bookingId,
    required String status,
  }) async {
    final response = await AppHttp.patch(
      Uri.parse("$baseUrl/logistics/lorries/$lorryId/cargo/$bookingId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": status}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createCampaign({
    required String farmerId,
    required String timelineRef,
    required String cropType,
    required String description,
    required double fundingGoalLkr,
    required double returnPercentage,
    required DateTime deadline,
  }) async {
    final response = await AppHttp.post(
      Uri.parse("$baseUrl/crowdfunding/campaigns"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "farmer": farmerId,
        "timelineRef": timelineRef,
        "cropType": cropType,
        "description": description,
        "fundingGoalLkr": fundingGoalLkr,
        "returnPercentage": returnPercentage,
        "deadline": deadline.toIso8601String(),
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMyCampaigns(String farmerId) async {
    final response = await AppHttp.get(Uri.parse("$baseUrl/crowdfunding/campaigns/mine?farmerId=$farmerId"));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> sendChatMessage({
    required String farmerId,
    required String message,
    required String language,
  }) async {
    final response = await AppHttp.post(
      Uri.parse("$baseUrl/chat/message"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"farmer": farmerId, "message": message, "language": language}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getChatHistory(String farmerId) async {
    final response = await AppHttp.get(Uri.parse("$baseUrl/chat/history?farmer=$farmerId"));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> generateReminders({
    required String farmerId,
    required String timelineRef,
    required String cropType,
    required double latitude,
    required double longitude,
    required DateTime plantingDate,
    required List<Map<String, dynamic>> milestones,
  }) async {
    final response = await AppHttp.post(
      Uri.parse("$baseUrl/reminders/generate"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "farmer": farmerId,
        "timelineRef": timelineRef,
        "cropType": cropType,
        "latitude": latitude,
        "longitude": longitude,
        "plantingDate": plantingDate.toIso8601String(),
        "milestones": milestones,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getReminders(String farmerId, {String? status}) async {
    final statusParam = status != null ? "&status=$status" : "";
    final response = await AppHttp.get(Uri.parse("$baseUrl/reminders?farmer=$farmerId$statusParam"));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateReminder({
    required String reminderId,
    required String status,
    String? linkedDiseaseLogId,
  }) async {
    final response = await AppHttp.patch(
      Uri.parse("$baseUrl/reminders/$reminderId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"status": status, if (linkedDiseaseLogId != null) "linkedDiseaseLogId": linkedDiseaseLogId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getNearbySuppliers({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    String? type,
  }) async {
    final typeParam = type != null ? "&type=$type" : "";
    final response = await AppHttp.get(
      Uri.parse("$baseUrl/suppliers/nearby?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm$typeParam"),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getCurrentUser(String token) async {
    final response = await AppHttp.get(
      Uri.parse("$baseUrl/auth/me"),
      headers: {"Authorization": "Bearer $token"},
    );
    return _handleResponse(response);
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded;
    } catch (_) {
      return {
        "success": false,
        "message": "Server returned an unexpected response (status ${response.statusCode}).",
      };
    }
  }
}