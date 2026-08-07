import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/smooth_route.dart';
import '../localization/app_locale.dart';
import '../widgets/shimmer_loading.dart';
import 'disease_scanner_screen.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<dynamic> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    final farmerId = await AuthService.getUserId();
    if (farmerId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final result = await ApiService.getReminders(farmerId, status: "pending");
    setState(() {
      _reminders = result["success"] == true ? (result["data"] as List) : [];
      _isLoading = false;
    });
  }

  Future<void> _dismiss(String id) async {
    await ApiService.updateReminder(reminderId: id, status: "dismissed");
    _loadReminders();
  }

  Future<void> _acknowledge(String id) async {
    await ApiService.updateReminder(reminderId: id, status: "acknowledged");
    _loadReminders();
  }

  Map<String, dynamic> _styleFor(String type) {
    switch (type) {
      case "weather_action":
        return {"icon": Icons.cloud_rounded, "color": AppColors.indigo, "bg": AppColors.indigoLight};
      case "disease_risk":
        return {"icon": Icons.bug_report_rounded, "color": AppColors.danger, "bg": AppColors.dangerLight};
      case "harvest_ready":
        return {"icon": Icons.agriculture_rounded, "color": AppColors.gold, "bg": AppColors.goldLight};
      case "milestone_due":
      default:
        return {"icon": Icons.event_busy_rounded, "color": AppColors.forest, "bg": AppColors.forestLight};
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return Scaffold(
      appBar: AppBar(title: Text(t("reminders"))),
      body: _isLoading
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [ShimmerCard(), ShimmerCard(), ShimmerCard()],
            )
          : _reminders.isEmpty
              ? EmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: t("allCaughtUp"),
                  subtitle: "Weather, disease, harvest, and task reminders will show up here as they come in.",
                )
              : RefreshIndicator(
                  onRefresh: _loadReminders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reminders.length,
                    itemBuilder: (context, index) {
                      final reminder = _reminders[index];
                      final style = _styleFor(reminder["type"]);

                      return FadeSlideIn(
                        delayMs: index * 50,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(color: style["bg"], borderRadius: BorderRadius.circular(10)),
                                    child: Icon(style["icon"], color: style["color"], size: 19),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(reminder["title"], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        Text(reminder["message"], style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted, height: 1.4)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (reminder["requiresPhoto"] == true)
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => Navigator.push(
                                          context,
                                          SmoothRoute(
                                            page: DiseaseScannerScreen(
                                              prefilledCropType: reminder["cropType"],
                                              reminderId: reminder["_id"],
                                            ),
                                          ),
                                        ).then((_) => _loadReminders()),
                                        icon: const Icon(Icons.camera_alt_rounded, size: 16),
                                        label: Text(t("uploadPhoto")),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.danger,
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                        ),
                                      ),
                                    )
                                  else
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _acknowledge(reminder["_id"]),
                                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                                        child: Text(t("gotIt")),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.inkMuted),
                                    tooltip: "Dismiss",
                                    onPressed: () => _dismiss(reminder["_id"]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
      },
    );
  }
}
