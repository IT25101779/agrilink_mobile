import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/timeline_model.dart';
import '../services/sync_service.dart';
import '../services/crop_recommendation_service.dart';
import '../services/soil_type_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/smooth_route.dart';
import 'timeline_detail_screen.dart';

class TimelineListScreen extends StatefulWidget {
  const TimelineListScreen({super.key});

  @override
  State<TimelineListScreen> createState() => _TimelineListScreenState();
}

class _TimelineListScreenState extends State<TimelineListScreen> {
  bool _isSyncing = false;

  Future<void> _manualSync() async {
    setState(() => _isSyncing = true);
    final box = Hive.box<TimelineModel>("timelines");
    final syncedCount = await SyncService.syncPendingTimelines(box);
    setState(() => _isSyncing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(syncedCount > 0 ? "Synced $syncedCount timeline(s)." : "No internet, or nothing to sync yet.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<TimelineModel>("timelines");

    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(color: AppColors.forestLight, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              const Icon(Icons.cloud_sync_rounded, color: AppColors.forest, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t("worksOffline"),
                  style: const TextStyle(fontSize: 12, color: AppColors.forest, fontWeight: FontWeight.w500),
                ),
              ),
              TextButton(
                onPressed: _isSyncing ? null : _manualSync,
                child: _isSyncing
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(t("syncNow"), style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: box.listenable(),
            builder: (context, Box<TimelineModel> box, _) {
              if (box.isEmpty) {
                return EmptyState(
                  icon: Icons.grass_rounded,
                  title: t("noActiveTimelines"),
                  subtitle: t("goToNavigatorHint"),
                );
              }

              final timelines = box.values.toList().reversed.toList();

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: timelines.length,
                itemBuilder: (context, index) {
                  final timeline = timelines[index];
                  return FadeSlideIn(
                    delayMs: index * 60,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.push(
                            context,
                            SmoothRoute(page: TimelineDetailScreen(timelineKey: timeline.localId)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        value: timeline.progressPercent / 100,
                                        strokeWidth: 4,
                                        backgroundColor: AppColors.border,
                                        color: AppColors.forest,
                                      ),
                                      Text("${timeline.progressPercent.round()}%",
                                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.forest)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        CropRecommendationService.sinhalaNameFor(timeline.cropType) != null
                                            ? "${timeline.cropType}  ·  ${CropRecommendationService.sinhalaNameFor(timeline.cropType)}"
                                            : timeline.cropType,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "${timeline.landSizeAcres} acres · ${SoilTypeService.bilingualLabel(timeline.soilType)}",
                                        style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted),
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(
                                            timeline.syncStatus == "synced" ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                                            size: 13,
                                            color: timeline.syncStatus == "synced" ? AppColors.forest : AppColors.gold,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            timeline.syncStatus == "synced" ? t("synced") : t("pendingSync"),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: timeline.syncStatus == "synced" ? AppColors.forest : AppColors.gold,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AppColors.inkMuted),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
      },
    );
  }
}
