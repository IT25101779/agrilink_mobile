import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timeline_model.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class ReminderEngine {
  static const _notifiedIdsKey = "notified_reminder_ids";

  /// Call on app open / Home screen init. For every active local timeline,
  /// asks the backend to generate any new weather/disease/harvest/overdue
  /// reminders (safe to call repeatedly — server dedupes), then fires a
  /// local notification for any reminder this device hasn't shown yet.
  static Future<void> refreshAndNotify(Box<TimelineModel> timelineBox) async {
    final farmerId = await AuthService.getUserId();
    if (farmerId == null) return;

    final activeTimelines = timelineBox.values.where((t) => t.status == "active").toList();

    for (final timeline in activeTimelines) {
      await ApiService.generateReminders(
        farmerId: farmerId,
        timelineRef: timeline.localId,
        cropType: timeline.cropType,
        latitude: timeline.latitude,
        longitude: timeline.longitude,
        plantingDate: timeline.plantingDate,
        milestones: timeline.milestones
            .map((m) => {"day": m.day, "title": m.title, "description": m.description, "isCompleted": m.isCompleted})
            .toList(),
      );
    }

    final result = await ApiService.getReminders(farmerId, status: "pending");
    if (result["success"] != true) return;

    final reminders = (result["data"] as List);
    final prefs = await SharedPreferences.getInstance();
    final notifiedIds = prefs.getStringList(_notifiedIdsKey)?.toSet() ?? <String>{};

    for (final reminder in reminders) {
      final id = reminder["_id"] as String;
      if (notifiedIds.contains(id)) continue;

      await NotificationService.showReminder(
        id: id.hashCode,
        title: reminder["title"],
        body: reminder["message"],
      );
      notifiedIds.add(id);
    }

    await prefs.setStringList(_notifiedIdsKey, notifiedIds.toList());
  }
}
