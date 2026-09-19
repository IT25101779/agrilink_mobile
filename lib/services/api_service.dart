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

  /// PATCH /api/marketplace/listings/:id — farmer edits their own listing
  /// (quantity, price, harvest date, quality grade, photos) while it's
  /// still in "listed" status. Previously there was no way to do this at
  /// all — a farmer who mistyped a price had no fix but to leave it wrong.
  static Future<Map<String, dynamic>> updateMarketplaceListing({
    required String listingId,
    required String farmerId,
    double? quantityKg,
    double? pricePerKg,
    DateTime? harvestDate,
    String? qualityGrade,
    List<String>? photos,
  }) async {
    final response = await AppHttp.patch(
      Uri.parse("$baseUrl/marketplace/listings/$listingId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "farmerId": farmerId,
        if (quantityKg != null) "quantityKg": quantityKg,
        if (pricePerKg != null) "pricePerKg": pricePerKg,
        if (harvestDate != null) "harvestDate": harvestDate.toIso8601String(),
        if (qualityGrade != null) "qualityGrade": qualityGrade,
        if (photos != null) "photos": photos,
      }),
    );
    return _handleResponse(response);
  }

  /// PATCH /api/marketplace/listings/:id/complete-sale — marks a reserved
  /// order as actually completed. Needed for AI price prediction to ever
  /// have real sold-price data to learn from (see backend
  /// pricePredictionEngine.js) — without this being called, every price
  /// estimate falls back to a generic asking-price average or flat default.
  static Future<Map<String, dynamic>> completeSale({
    required String listingId,
    required String confirmedByUserId,
  }) async {
    final response = await AppHttp.patch(
      Uri.parse("$baseUrl/marketplace/listings/$listingId/complete-sale"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"confirmedBy": confirmedByUserId}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPricePrediction(String cropType) async {
    final response = await AppHttp.get(Uri.parse("$baseUrl/price-predict/$cropType"));
    return _handleResponse(response);
  }

  /// language: pass the farmer's current UI language ("si"/"ta"/"en") so
  /// the backend translates the disease name, severity, symptoms, and
  /// treatment steps in the response. The database always stores the
  /// English original regardless — see backend diseaseController.js.
  static Future<Map<String, dynamic>> scanCropDisease({
    required String farmerId,
    required String cropType,
    required String imageBase64,
    required double latitude,
    required double longitude,
    String? district,
    String language = "en",
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
        "language": language,
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

  /// PATCH /api/crowdfunding/campaigns/:id/repay — the backend endpoint
  /// existed already, but nothing in the app ever called it, so a farmer
  /// had no way to actually trigger the credit-score-boost repayment flow
  /// your proposal describes. Should only be called once a campaign's
  /// status is "funded" — see the button added to TimelineDetailScreen.
  static Future<Map<String, dynamic>> repayCampaign(String campaignId) async {
    final response = await AppHttp.patch(
      Uri.parse("$baseUrl/crowdfunding/campaigns/$campaignId/repay"),
      headers: {"Content-Type": "application/json"},
    );
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

  static Future<Map<String, dynamic>> getMyTimelines(String farmerId, {String? status}) async {
    final statusParam = status != null ? "&status=$status" : "";
    final response = await AppHttp.get(Uri.parse("$baseUrl/timelines/mine?farmerId=$farmerId$statusParam"));
    return _handleResponse(response);
  }

  /// GET /api/ads?activeOnly=true — banner ads for the farmer app.
  /// Previously the admin Ad Scheduler could create ads, but nothing in
  /// the farmer app ever fetched or displayed them.
  static Future<Map<String, dynamic>> getActiveAds({
    String? cropType,
    String? timelinePhase,
    String? district,
  }) async {
    final params = <String>["activeOnly=true"];
    if (cropType != null) params.add("cropType=$cropType");
    if (timelinePhase != null) params.add("timelinePhase=$timelinePhase");
    if (district != null) params.add("district=$district");
    final response = await AppHttp.get(Uri.parse("$baseUrl/ads?${params.join('&')}"));
    return _handleResponse(response);
  }

  static Future<void> trackAdImpression(String adId) async {
    try {
      await AppHttp.post(Uri.parse("$baseUrl/ads/$adId/impression"));
    } catch (_) {
      // Fire-and-forget — a failed impression ping shouldn't affect the UI.
    }
  }

  static Future<void> trackAdClick(String adId) async {
    try {
      await AppHttp.post(Uri.parse("$baseUrl/ads/$adId/click"));
    } catch (_) {
      // Fire-and-forget, same as above.
    }
  }

  // ---- Community Marketplace (farmer-posted rentals & seeds) ----

  static Future<Map<String, dynamic>> createCommunityListing({
    required String farmerId,
    required String listingType, // "equipment_rental" | "seeds_for_sale" | "other"
    required String title,
    required String description,
    required double priceAmount,
    required String priceUnit,
    required double latitude,
    required double longitude,
    required String district,
    String? contactPhone,
    List<String> photos = const [],
  }) async {
    final response = await AppHttp.post(
      Uri.parse("$baseUrl/community-listings"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "farmer": farmerId,
        "listingType": listingType,
        "title": title,
        "description": description,
        "priceInfo": {"amount": priceAmount, "unit": priceUnit},
        "latitude": latitude,
        "longitude": longitude,
        "district": district,
        if (contactPhone != null) "contactPhone": contactPhone,
        "photos": photos,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getNearbyCommunityListings({
    required double latitude,
    required double longitude,
    double radiusKm = 25,
    String? listingType,
  }) async {
    final typeParam = listingType != null ? "&listingType=$listingType" : "";
    final response = await AppHttp.get(
      Uri.parse("$baseUrl/community-listings/nearby?latitude=$latitude&longitude=$longitude&radiusKm=$radiusKm$typeParam"),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getMyCommunityListings(String farmerId) async {
    final response = await AppHttp.get(Uri.parse("$baseUrl/community-listings/mine?farmerId=$farmerId"));
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateCommunityListing({
    required String listingId,
    required String farmerId,
    String? title,
    String? description,
    double? priceAmount,
    String? priceUnit,
    bool? isActive,
    String? contactPhone,
  }) async {
    final response = await AppHttp.patch(
      Uri.parse("$baseUrl/community-listings/$listingId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "farmerId": farmerId,
        if (title != null) "title": title,
        if (description != null) "description": description,
        if (priceAmount != null && priceUnit != null) "priceInfo": {"amount": priceAmount, "unit": priceUnit},
        if (isActive != null) "isActive": isActive,
        if (contactPhone != null) "contactPhone": contactPhone,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteCommunityListing({
    required String listingId,
    required String farmerId,
  }) async {
    final response = await AppHttp.delete(
      Uri.parse("$baseUrl/community-listings/$listingId?farmerId=$farmerId"),
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
