import 'package:flutter/material.dart';
import '../services/crop_recommendation_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/crop_thumbnail.dart';
import '../widgets/fade_slide_in.dart';

class SeasonalCalendarScreen extends StatefulWidget {
  const SeasonalCalendarScreen({super.key});

  @override
  State<SeasonalCalendarScreen> createState() => _SeasonalCalendarScreenState();
}

class _SeasonalCalendarScreenState extends State<SeasonalCalendarScreen> {
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now().month;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        final cropsThisMonth = CropRecommendationService.catalogue
            .where((c) => c.bestPlantingMonths.contains(_selectedMonth))
            .toList();

        return Scaffold(
          appBar: AppBar(title: Text(t("seasonalCalendar"))),
          body: Column(
            children: [
              SizedBox(
                height: 84,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final isSelected = month == _selectedMonth;
                    final isCurrentMonth = month == DateTime.now().month;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMonth = month),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.forest : AppColors.forestLight,
                          borderRadius: BorderRadius.circular(14),
                          border: isCurrentMonth && !isSelected ? Border.all(color: AppColors.forest, width: 1.5) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              t("month$month").substring(0, 3),
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.forest,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$month",
                              style: TextStyle(
                                color: isSelected ? Colors.white70 : AppColors.forest.withOpacity(0.6),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${t("bestTimeToPlant")} — ${t("month$_selectedMonth")}",
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: cropsThisMonth.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            t("noCropsForMonth"),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.inkMuted),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: cropsThisMonth.length,
                        itemBuilder: (context, index) {
                          final crop = cropsThisMonth[index];
                          return FadeSlideIn(
                            delayMs: index * 40,
                            child: Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CropThumbnail(wikiImageTitle: crop.wikiImageTitle, size: 44),
                                title: Text("${crop.name}  ·  ${crop.nameSi}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                subtitle: Text(
                                  "${crop.category.label} · ${AppLocale.instance.t("growthCycle")}: ${crop.growthDurationDays} ${AppLocale.instance.t("days")}",
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
