import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'app_http.dart';
import 'dart:convert';
import '../models/timeline_model.dart';
import '../models/milestone_model.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'crop_recommendation_service.dart';

/// NOTE ON MULTI-DEVICE / CROSS-SESSION SYNC:
/// This service handles BOTH directions of sync:
///   - syncPendingTimelines() — PUSH: uploads locally-created/edited
///     timelines to the backend. This is the original sync logic.
///   - pullRemoteTimelines() — PULL: downloads timelines the backend has
///     for this farmer (created on ANY device, including this one in a
///     past session) into local storage. Added after discovering that
///     without it, a second device or a reinstalled app never sees data
///     that's already safely on the server — it only ever sees whatever
///     happens to be in its own local Hive box.
///
/// Conflict handling is intentionally simple (documented in
/// agrilink-backend/ARCHITECTURE.md as "last-write-wins per field group"):
/// a local record with unsynced edits (syncStatus == "pending") is never
/// overwritten by a pull — it's left for syncPendingTimelines to push up
/// instead, so the newer edit (wherever it happened) ultimately wins on
/// the server, and every device converges to that on its next pull. Two
/// devices editing the SAME timeline while both offline, at the same
/// time, is a known unresolved edge case — the later push wins and the
/// earlier device's edit is silently overwritten. That's an acceptable
/// limitation for this stage, not a bug we're chasing right now.
class SyncService {
  static final Connectivity _connectivity = Connectivity();

  static Future<bool> _hasInternet() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  /// Call this on app start and whenever connectivity changes.
  static void listenAndAutoSync(Box<TimelineModel> timelineBox) {
    _connectivity.onConnectivityChanged.listen((results) async {
      if (!results.contains(ConnectivityResult.none)) {
        await syncPendingTimelines(timelineBox);
        await pullRemoteTimelines(box: timelineBox);
      }
    });
  }

  /// Pushes every locally-stored timeline with syncStatus == "pending"
  /// up to the cloud. Marks each one "synced" on success, leaves it
  /// "pending" on failure so it retries next time connectivity returns.
  static Future<int> syncPendingTimelines(Box<TimelineModel> timelineBox) async {
    if (!await _hasInternet()) return 0;

    int syncedCount = 0;
    final pendingKeys = timelineBox.keys.where((key) {
      final item = timelineBox.get(key);
      return item != null && item.syncStatus == "pending";
    }).toList();

    for (final key in pendingKeys) {
      final timeline = timelineBox.get(key);
      if (timeline == null) continue;

      try {
        final response = await AppHttp.post(
          Uri.parse("${ApiService.baseUrl}/timelines/sync-queue"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(timeline.toSyncJson()),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          timeline.syncStatus = "synced";
          timeline.lastSyncedAt = DateTime.now();
          await timeline.save();
          syncedCount++;
        }
      } catch (_) {
        // Network dropped mid-sync — leave as pending, will retry automatically.
        continue;
      }
    }
    return syncedCount;
  }

  /// Downloads every timeline the backend has for the logged-in farmer
  /// and merges it into local storage — the "other half" of sync. Safe
  /// to call as often as you like (e.g. every app open, every pull-to-
  /// refresh, after every manual "Sync Now" tap); it never touches a
  /// local record that still has unsynced edits.
  ///
  /// Returns how many local records were created/updated from the server.
  static Future<int> pullRemoteTimelines({required Box<TimelineModel> box}) async {
    if (!await _hasInternet()) return 0;

    final farmerId = await AuthService.getUserId();
    if (farmerId == null) return 0;

    try {
      final result = await ApiService.getMyTimelines(farmerId);
      if (result["success"] != true) return 0;

      final remoteList = (result["data"] as List?) ?? [];
      int pulledCount = 0;

      for (final raw in remoteList) {
        final json = raw as Map<String, dynamic>;
        final localId = json["localId"] as String?;
        if (localId == null || localId.isEmpty) {
          // A record without a localId can't be matched back to a Hive
          // key — shouldn't happen for anything created via this app,
          // but skip rather than crash if it ever does.
          continue;
        }

        final existing = box.get(localId);
        if (existing != null && existing.syncStatus == "pending") {
          // This device has unsynced edits — don't overwrite them with a
          // (possibly older) server copy. syncPendingTimelines will push
          // this device's version up instead.
          continue;
        }

        final timeline = _timelineFromServerJson(json, localId);
        await box.put(localId, timeline);
        pulledCount++;
      }
      return pulledCount;
    } catch (_) {
      // Network dropped mid-pull, or an unexpected response shape —
      // fail quietly, exactly like syncPendingTimelines does, so a
      // transient network blip never surfaces as a crash.
      return 0;
    }
  }

  /// Runs both directions in the right order: push local edits up first,
  /// then pull (so this device's own just-pushed edits come right back
  /// down consistently, alongside anything from other devices). Use this
  /// for the "Sync Now" button and other explicit, user-triggered syncs.
  static Future<Map<String, int>> fullSync(Box<TimelineModel> box) async {
    final pushed = await syncPendingTimelines(box);
    final pulled = await pullRemoteTimelines(box: box);
    return {"pushed": pushed, "pulled": pulled};
  }

  static TimelineModel _timelineFromServerJson(Map<String, dynamic> json, String localId) {
    final coordinates = (json["gpsLocation"]?["coordinates"] as List?) ?? [80.6337, 7.2906];
    final longitude = (coordinates[0] as num).toDouble();
    final latitude = (coordinates[1] as num).toDouble();

    final farmerField = json["farmer"];
    final farmerId = farmerField is Map ? (farmerField["_id"] as String? ?? "") : (farmerField as String? ?? "");

    final milestonesJson = (json["milestones"] as List?) ?? [];
    final milestones = milestonesJson.map((m) {
      final map = m as Map<String, dynamic>;
      final title = map["title"] as String? ?? "";
      // The backend only stores English title/description — reconstruct
      // the Sinhala text locally from the same stage templates used to
      // generate it in the first place, so a timeline pulled onto a
      // second device still shows correctly in Sinhala.
      final bilingual = CropRecommendationService.bilingualForStageTitle(title);
      return MilestoneModel(
        day: (map["day"] as num?)?.toInt() ?? 0,
        title: title,
        description: map["description"] as String? ?? "",
        titleSi: bilingual?["titleSi"],
        descriptionSi: bilingual?["descriptionSi"],
        isCompleted: map["isCompleted"] as bool? ?? false,
        completedAt: map["completedAt"] != null ? DateTime.tryParse(map["completedAt"] as String) : null,
        weatherAlertTriggered: map["weatherAlertTriggered"] as bool? ?? false,
      );
    }).toList();

    return TimelineModel(
      localId: localId,
      farmerId: farmerId,
      cropType: json["cropType"] as String? ?? "",
      landSizeAcres: (json["landSizeAcres"] as num?)?.toDouble() ?? 0,
      soilType: json["soilType"] as String? ?? "loamy",
      latitude: latitude,
      longitude: longitude,
      plantingDate: DateTime.tryParse(json["plantingDate"] as String? ?? "") ?? DateTime.now(),
      expectedHarvestDate: DateTime.tryParse(json["expectedHarvestDate"] as String? ?? "") ?? DateTime.now(),
      milestones: milestones,
      status: json["status"] as String? ?? "active",
      syncStatus: "synced",
      lastLocalModifiedAt: DateTime.tryParse(json["lastLocalModifiedAt"] as String? ?? "") ?? DateTime.now(),
      lastSyncedAt: DateTime.now(),
    );
  }
}
