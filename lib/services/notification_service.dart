import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Shows local notification pop-ups while the app is running/foregrounded.
///
/// HONEST SCOPE NOTE: this covers notifications while the app process is
/// alive (foreground or backgrounded-but-not-killed). True "always on"
/// push notifications that wake a fully closed app require Firebase Cloud
/// Messaging with a server-side trigger — a heavier native setup (Firebase
/// project, google-services.json, APNs certs for iOS) that's a reasonable
/// "Phase 2" item rather than something to rush into a hackathon prototype.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> showReminder({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();

    const androidDetails = AndroidNotificationDetails(
      'agrilink_reminders',
      'Crop Reminders',
      channelDescription: 'Weather, disease, harvest, and task reminders for your crops',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(id, title, body, details);
  }
}
