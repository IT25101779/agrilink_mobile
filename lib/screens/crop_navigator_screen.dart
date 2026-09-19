import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/timeline_model.dart';
import '../services/crop_recommendation_service.dart';
import '../services/auth_service.dart';
import '../services/climate_zone_service.dart';
import '../services/soil_type_service.dart';
import '../services/insights_api.dart';
import '../localization/tr.dart';
import '../widgets/ui_kit.dart';
import '../widgets/profit_planner_sheet.dart';
import '../localization/app_locale.dart';
import '../theme/app_theme.dart';
import '../widgets/crop_thumbnail.dart';
import '../widgets/smooth_route.dart';
import 'suppliers_screen.dart';
import 'seasonal_calendar_screen.dart';
import 'community_marketplace_screen.dart';

class CropNavigatorScreen extends StatefulWidget {
  const CropNavigatorScreen({super.key});

  @override
  State<CropNavigatorScreen> createState() => _CropNavigatorScreenState();
}

class _CropNavigatorScreenState extends State<CropNavigatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _landSizeController = TextEditingController();

  String _soilType = "loamy";
  String? _district;
  String _climateZone = "intermediate";
  CropCategory? _selectedCategory;
  List<CropOption> _recommendations = [];
  bool _hasSearched = false;

  // ---- Oversupply Guard data (how many farmers in this district already grow each crop) ----
  Map<String, Map<String, dynamic>> _cropSignals = {};
  Map<String, Map<String, dynamic>> _cropDemand = {};
  bool _signalsEnoughData = false;
  bool _signalsLoaded = false;
  int _signalsTotalPlantings = 0;

  final List<String> _soilTypes = SoilTypeService.allTypes;

  @override
  void initState() {
    super.initState();
    _loadDistrict();
  }

  Future<void> _loadDistrict() async {
    final district = await AuthService.getDistrict();
    setState(() {
      _district = district;
      _climateZone = ClimateZoneService.zoneForDistrict(district);
    });
    _loadSignals();
  }

  /// OVERSUPPLY GUARD: asks the server how many farmers in this district are
  /// already growing each crop (anonymous counts only) and what buyers want.
  Future<void> _loadSignals() async {
    final result = await InsightsApi.getPlantingSignals(district: _district);
    if (!mounted || result["success"] != true || result["data"] is! Map) return;
    final data = Map<String, dynamic>.from(result["data"] as Map);
    final signals = <String, Map<String, dynamic>>{};
    for (final c in (data["crops"] as List? ?? [])) {
      final crop = Map<String, dynamic>.from(c as Map);
      signals["${crop["cropType"]}".toLowerCase()] = crop;
    }
    final demand = <String, Map<String, dynamic>>{};
    for (final d in (data["demand"] as List? ?? [])) {
      final item = Map<String, dynamic>.from(d as Map);
      demand["${item["cropType"]}".toLowerCase()] = item;
    }
    setState(() {
      _cropSignals = signals;
      _cropDemand = demand;
      _signalsEnoughData = data["enoughData"] == true;
      _signalsTotalPlantings = (data["totalPlantings"] as num?)?.toInt() ?? 0;
      _signalsLoaded = true;
    });
  }

  /// PROFIT PLANNER for the plot size the farmer typed in above.
  void _openProfitPlan(CropOption crop) {
    final acres = double.tryParse(_landSizeController.text) ?? 1.0;
    ProfitPlannerSheet.show(context, cropType: crop.name, acres: acres <= 0 ? 1.0 : acres);
  }

  Map<String, dynamic>? _signalFor(CropOption crop) => _cropSignals[crop.name.toLowerCase()];
  Map<String, dynamic>? _demandFor(CropOption crop) => _cropDemand[crop.name.toLowerCase()];

  /// Small badges shown under a recommended crop.
  List<Widget> _signalPills(CropOption crop) {
    final pills = <Widget>[];
    final signal = _signalFor(crop);
    final demand = _demandFor(crop);
    final level = signal == null ? "" : "${signal["level"]}";
    final farmers = (signal?["farmers"] as num?)?.toInt() ?? 0;

    if (_signalsEnoughData && level == "high") {
      pills.add(StatusPill(
        label: tr("Crowded: $farmers farmers growing", "අධික සැපයුම: ගොවීන් $farmers දෙනෙක් වගා කරයි"),
        color: AppColors.danger,
        icon: Icons.warning_amber_rounded,
      ));
    } else if (_signalsEnoughData && level == "medium") {
      pills.add(StatusPill(
        label: tr("Getting busy: $farmers farmers", "කාර්යබහුලයි: ගොවීන් $farmers"),
        color: AppColors.gold,
        icon: Icons.groups_rounded,
      ));
    } else if (_signalsEnoughData) {
      pills.add(StatusPill(label: tr("Room in the market", "වෙළඳපොළේ ඉඩ ඇත"), color: AppColors.forest, icon: Icons.check_rounded));
    }
    if (demand != null) {
      pills.add(StatusPill(
        label: tr("Buyers need ${priceText(numOf(demand["totalKg"]))} kg", "ගැනුම්කරුවන්ට කි.ග්‍රෑ. ${priceText(numOf(demand["totalKg"]))} ක් අවශ්‍යයි"),
        color: AppColors.indigo,
        icon: Icons.campaign_rounded,
      ));
    }
    return pills;
  }

  /// Shown when the farmer taps "Start" on a crop many neighbours already grow.
  Future<bool> _confirmCrowded(CropOption crop, Map<String, dynamic> signal) async {
    final farmers = (signal["farmers"] as num?)?.toInt() ?? 0;
    final share = numOf(signal["sharePercent"]);

    // Better options from the SAME recommendation list: not crowded, most wanted by buyers first.
    final alternatives = _recommendations.where((c) {
      if (c.name == crop.name) return false;
      final s = _signalFor(c);
      return s == null || "${s["level"]}" != "high";
    }).toList()
      ..sort((a, b) {
        final da = numOf(_demandFor(a)?["totalKg"]);
        final db = numOf(_demandFor(b)?["totalKg"]);
        if (da != db) return db.compareTo(da);
        final fa = (_signalFor(a)?["farmers"] as num?)?.toInt() ?? 0;
        final fb = (_signalFor(b)?["farmers"] as num?)?.toInt() ?? 0;
        return fa.compareTo(fb);
      });
    final top = alternatives.take(3).toList();

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Expanded(child: Text(tr("Many neighbours grow this", "බොහෝ අසල්වැසියන් මෙය වගා කරයි"), style: const TextStyle(fontSize: 17))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr(
                  "$farmers farmers in ${_district ?? "your district"} are already growing ${crop.name} (${share.toStringAsFixed(0)}% of all crops there). If they harvest together, prices can fall.",
                  "${_district ?? "ඔබේ දිස්ත්‍රික්කයේ"} ගොවීන් $farmers දෙනෙක් දැනටමත් ${crop.name} වගා කරයි (එහි මුළු බෝග වලින් ${share.toStringAsFixed(0)}%). ඔවුන් එකවර අස්වැන්න නෙළුවොත් මිල පහත වැටිය හැක.",
                ),
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
              if (top.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(tr("Less crowded options for you:", "ඔබට අඩු තදබදයක් ඇති විකල්ප:"), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                ...top.map((c) {
                  final d = _demandFor(c);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      "• ${c.name}${d != null ? "  (${tr("buyers need", "ගැනුම්කරුවන්ට අවශ්‍යයි")} ${priceText(numOf(d["totalKg"]))} kg)" : ""}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr("Choose another", "වෙනත් එකක් තෝරන්න"))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr("Start anyway", "කෙසේ වෙතත් අරඹන්න")),
          ),
        ],
      ),
    );
    return proceed == true;
  }

  /// Summary card: what is being grown around you right now.
  Widget _guardSummary() {
    if (!_signalsLoaded || _district == null || _district!.isEmpty) return const SizedBox.shrink();
    final crops = _cropSignals.values.toList()
      ..sort((a, b) => ((b["farmers"] as num?) ?? 0).compareTo((a["farmers"] as num?) ?? 0));
    final top = crops.take(4).toList();

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_moon_rounded, size: 18, color: AppColors.forest),
              const SizedBox(width: 6),
              Expanded(
                child: Text(tr("Oversupply Guard · $_district", "අධි සැපයුම් ආරක්ෂකය · $_district"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_signalsEnoughData)
            Text(
              tr(
                "Not enough farmers here have shared their crops yet ($_signalsTotalPlantings so far). This will fill in as more farmers use the app.",
                "මෙහි ගොවීන් තවම ප්‍රමාණවත් තරම් තම බෝග බෙදාගෙන නැත (මෙතෙක් $_signalsTotalPlantings). වැඩි ගොවීන් යෙදුම භාවිත කරන විට මෙය පිරෙනු ඇත.",
              ),
              style: TextStyle(fontSize: 12.5, color: mutedOf(context), height: 1.4),
            )
          else ...[
            Text(
              tr("What farmers near you are growing right now:", "ඔබ අසල ගොවීන් දැන් වගා කරන දේ:"),
              style: TextStyle(fontSize: 12.5, color: mutedOf(context)),
            ),
            const SizedBox(height: 8),
            ...top.map((c) {
              final level = "${c["level"]}";
              final color = level == "high" ? AppColors.danger : level == "medium" ? AppColors.gold : AppColors.forest;
              final label = level == "high" ? tr("Crowded", "තදබදයි") : level == "medium" ? tr("Busy", "කාර්යබහුලයි") : tr("OK", "හොඳයි");
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(child: Text("${c["cropType"]}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    Text(tr("${c["farmers"]} farmers", "ගොවීන් ${c["farmers"]}"), style: TextStyle(fontSize: 12, color: mutedOf(context))),
                    const SizedBox(width: 8),
                    StatusPill(label: label, color: color),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 4),
          Text(
            tr("Only anonymous counts are shown. No farmer's name or land is shared.", "පෙන්වන්නේ නිර්නාමික ගණන් පමණි. කිසිදු ගොවියෙකුගේ නමක් හෝ ඉඩමක් බෙදා නොගනී."),
            style: TextStyle(fontSize: 11, color: mutedOf(context)),
          ),
        ],
      ),
    );
  }

  void _getRecommendations() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _recommendations = CropRecommendationService.recommend(
        soilType: _soilType,
        climateZone: _climateZone,
        category: _selectedCategory,
      );
      _hasSearched = true;
    });
  }

  Future<void> _startTimeline(CropOption crop) async {
    final signal = _signalFor(crop);
    if (_signalsEnoughData && signal != null && "${signal["level"]}" == "high") {
      final proceed = await _confirmCrowded(crop, signal);
      if (!proceed) return;
    }
    final landSize = double.tryParse(_landSizeController.text) ?? 1.0;
    final milestones = CropRecommendationService.generateMilestoneTimeline(crop);
    final now = DateTime.now();
    final farmerId = await AuthService.getUserId() ?? "unknown-farmer";

    final timeline = TimelineModel(
      localId: const Uuid().v4(),
      farmerId: farmerId,
      cropType: crop.name,
      landSizeAcres: landSize,
      soilType: _soilType,
      latitude: 7.2906, // placeholder GPS until geolocator permission flow is added
      longitude: 80.6337,
      plantingDate: now,
      expectedHarvestDate: now.add(Duration(days: crop.growthDurationDays)),
      milestones: milestones,
      lastLocalModifiedAt: now,
      syncStatus: "pending",
    );

    final box = Hive.box<TimelineModel>("timelines");
    await box.put(timeline.localId, timeline);
    HapticFeedback.mediumImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${crop.name} timeline created! Saved offline — check 'My Timelines' tab.")),
      );
      setState(() {
        _recommendations = [];
        _hasSearched = false;
        _landSizeController.clear();
      });
    }
  }

  Widget _categoryChip(CropCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12.5)),
        selected: isSelected,
        selectedColor: AppColors.forest,
        backgroundColor: AppColors.forestLight,
        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.forest, fontWeight: FontWeight.w600),
        onSelected: (_) {
          setState(() => _selectedCategory = category);
          if (_hasSearched) _getRecommendations();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocale.instance.t("tellUsAboutLand"),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (_district != null && _district!.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.forestLight, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: AppColors.forest),
                      const SizedBox(width: 6),
                      Text(
                        "$_district — ${ClimateZoneService.zoneLabels[_climateZone]}",
                        style: const TextStyle(fontSize: 12.5, color: AppColors.forest, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              _guardSummary(),
              TextFormField(
                controller: _landSizeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocale.instance.t("landSizeAcres"),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please enter land size";
                  if (double.tryParse(value) == null) return "Enter a valid number";
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _soilType,
                decoration: InputDecoration(
                  labelText: AppLocale.instance.t("soilType"),
                  border: const OutlineInputBorder(),
                ),
                items: _soilTypes
                    .map((soil) => DropdownMenuItem(value: soil, child: Text(SoilTypeService.bilingualLabel(soil))))
                    .toList(),
                onChanged: (value) => setState(() => _soilType = value ?? "loamy"),
              ),
              const SizedBox(height: 16),
              Text("Category", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.inkMuted)),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _categoryChip(null, "All"),
                    ...CropCategory.values.map((c) => _categoryChip(c, c.label)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _getRecommendations,
                  icon: const Icon(Icons.eco),
                  label: Text(AppLocale.instance.t("getCropRecommendations")),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(height: 20),
              if (_hasSearched && _recommendations.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("No crops match this combination. Try a different category or soil type.", style: TextStyle(color: AppColors.inkMuted)),
                  ),
                ),
              if (_recommendations.isNotEmpty) ...[
                Text("${AppLocale.instance.t("recommendedCrops")} (${_recommendations.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ..._recommendations.map(
                  (crop) => Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      isThreeLine: true,
                      leading: CropThumbnail(wikiImageTitle: crop.wikiImageTitle, size: 44),
                      title: Text("${crop.name}  ·  ${crop.nameSi}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${crop.category.label} · ${AppLocale.instance.t("growthCycle")}: ${crop.growthDurationDays} ${AppLocale.instance.t("days")}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          if (_signalPills(crop).isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(spacing: 5, runSpacing: 5, children: _signalPills(crop)),
                          ],
                          if (crop.category != CropCategory.plantation)
                            TextButton.icon(
                              onPressed: () => _openProfitPlan(crop),
                              icon: const Icon(Icons.calculate_rounded, size: 16),
                              label: Text(tr("Profit estimate", "ලාභ ඇස්තමේන්තුව"), style: const TextStyle(fontSize: 12.5)),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 32),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.centerLeft,
                              ),
                            ),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => _startTimeline(crop),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
                        child: Text(AppLocale.instance.t("startTimeline"), style: const TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, SmoothRoute(page: const SuppliersScreen())),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: Text(AppLocale.instance.t("findNearbySuppliers")),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, SmoothRoute(page: const CommunityMarketplaceScreen())),
                  icon: const Icon(Icons.handshake_outlined, size: 18),
                  label: Text(AppLocale.instance.t("communityMarketplace")),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, SmoothRoute(page: const SeasonalCalendarScreen())),
                  icon: const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(AppLocale.instance.t("seasonalCalendar")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
