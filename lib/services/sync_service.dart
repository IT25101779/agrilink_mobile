import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'app_http.dart';
import '../models/timeline_model.dart';
import 'api_service.dart';

/// NOTE: This service calls POST {baseUrl}/timelines/sync-queue.
/// That route is the next backend increment (a /timelines router mirroring
/// the /marketplace router already built) — the client-side logic here is
/// fully implemented and ready to go live the moment that route is added,
/// so nothing needs to change in this file later.
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
}
