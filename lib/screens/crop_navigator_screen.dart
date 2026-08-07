import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/timeline_model.dart';
import '../services/crop_recommendation_service.dart';
import '../services/auth_service.dart';
import '../services/climate_zone_service.dart';
import '../services/soil_type_service.dart';
import '../localization/app_locale.dart';
import '../theme/app_theme.dart';
import '../widgets/crop_thumbnail.dart';
import '../widgets/smooth_route.dart';
import 'suppliers_screen.dart';
import 'seasonal_calendar_screen.dart';

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
                      leading: CropThumbnail(wikiImageTitle: crop.wikiImageTitle, size: 44),
                      title: Text("${crop.name}  ·  ${crop.nameSi}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                      subtitle: Text(
                        "${crop.category.label} · ${AppLocale.instance.t("growthCycle")}: ${crop.growthDurationDays} ${AppLocale.instance.t("days")}",
                        style: const TextStyle(fontSize: 12),
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
