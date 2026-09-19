import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../localization/app_locale.dart';
import '../models/timeline_model.dart';
import '../services/auth_service.dart';
import '../services/crop_recommendation_service.dart';
import '../theme/app_theme.dart';
import 'crop_thumbnail.dart';

bool _isSinhala() => AppLocale.instance.languageCode == "si";
String _s(String en, String si) => _isSinhala() ? si : en;

String _titleCase(String input) {
  return input
      .trim()
      .split(RegExp(r"\s+"))
      .map((word) => word.isEmpty ? word : "${word[0].toUpperCase()}${word.substring(1)}")
      .join(" ");
}

/// A crop selector that looks like a normal text field but opens a
/// searchable list when tapped, instead of letting the farmer type free text.
///
/// WHY THIS EXISTS: the server matches crop names EXACTLY (price prediction,
/// outbreak clusters, marketplace filters). When farmers typed the crop by
/// hand, "tomato", "Tomato " and "tamato" were three different crops, so
/// price history and outbreak alerts silently failed to match. Picking from
/// the app's own crop catalogue guarantees the same spelling everywhere.
///
/// It works with an ordinary [TextEditingController], so a screen can keep
/// reading `controller.text` exactly as it did with a TextField.
///
/// - The farmer's own active crops are shown first ("Your crops").
/// - The list is searchable in English or Sinhala.
/// - If a crop is not in the catalogue, the search box offers
///   'Use "<text>"' so nobody is ever blocked.
class CropPickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  /// Called once, right after the farmer picks a crop.
  final ValueChanged<String>? onSelected;

  /// Optional form validation (for use inside a Form).
  final String? Function(String?)? validator;

  const CropPickerField({
    super.key,
    required this.controller,
    required this.label,
    this.onSelected,
    this.validator,
  });

  /// Looks a crop up in the app's catalogue by name (ignores capitals/spaces).
  static CropOption? findCrop(String name) {
    final wanted = name.trim().toLowerCase();
    if (wanted.isEmpty) return null;
    for (final crop in CropRecommendationService.catalogue) {
      if (crop.name.toLowerCase() == wanted) return crop;
    }
    return null;
  }

  /// Crop names of the logged-in farmer's ACTIVE timelines, most recently
  /// updated first, without duplicates. Empty if nobody is logged in.
  static Future<List<String>> activeCropNames() async {
    final farmerId = await AuthService.getUserId();
    if (farmerId == null || !Hive.isBoxOpen("timelines")) return [];

    final box = Hive.box<TimelineModel>("timelines");
    final active = box.values
        .where((timeline) => timeline.farmerId == farmerId && timeline.status == "active")
        .toList()
      ..sort((a, b) => b.lastLocalModifiedAt.compareTo(a.lastLocalModifiedAt));

    final seen = <String>{};
    final names = <String>[];
    for (final timeline in active) {
      if (seen.add(timeline.cropType.toLowerCase())) {
        names.add(timeline.cropType);
      }
    }
    return names;
  }

  Future<void> _openPicker(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final yourCrops = await activeCropNames();
    if (!context.mounted) return;

    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CropPickerSheet(yourCrops: yourCrops, currentValue: controller.text),
    );

    if (picked != null && picked.isNotEmpty) {
      controller.text = picked;
      onSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      validator: validator,
      onTap: () => _openPicker(context),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
      ),
    );
  }
}

class _CropPickerSheet extends StatefulWidget {
  final List<String> yourCrops;
  final String currentValue;

  const _CropPickerSheet({required this.yourCrops, required this.currentValue});

  @override
  State<_CropPickerSheet> createState() => _CropPickerSheetState();
}

class _CropPickerSheetState extends State<_CropPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesQuery(CropOption crop) {
    final query = _query.trim();
    if (query.isEmpty) return true;
    return crop.name.toLowerCase().contains(query.toLowerCase()) || crop.nameSi.contains(query);
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkMuted, letterSpacing: 0.4),
      ),
    );
  }

  Widget _cropTile(CropOption crop) {
    final sinhala = _isSinhala();
    final selected = crop.name.toLowerCase() == widget.currentValue.trim().toLowerCase();
    return ListTile(
      leading: CropThumbnail(wikiImageTitle: crop.wikiImageTitle, size: 40),
      title: Text(sinhala ? crop.nameSi : crop.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(sinhala ? crop.name : crop.nameSi),
      trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.forest) : null,
      onTap: () => Navigator.pop(context, crop.name),
    );
  }

  // A crop name from one of the farmer's timelines. Normally it is in the
  // catalogue (with a photo); if not, it still works as a plain entry.
  Widget _yourCropTile(String name) {
    final crop = CropPickerField.findCrop(name);
    if (crop != null) return _cropTile(crop);
    return ListTile(
      leading: const Icon(Icons.eco_rounded, color: AppColors.forest),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () => Navigator.pop(context, name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final results = CropRecommendationService.catalogue.where(_matchesQuery).toList();
    final showYourCrops = query.isEmpty && widget.yourCrops.isNotEmpty;
    final showCustomOption = query.isNotEmpty && CropPickerField.findCrop(query) == null;

    return Padding(
      // Lifts the sheet above the keyboard while searching.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: _s("Search crop", "බෝගය සොයන්න"),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (showCustomOption)
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline_rounded, color: AppColors.indigo),
                      title: Text(_s('Use "$query"', '"$query" භාවිතා කරන්න')),
                      subtitle: Text(_s("Not in the list? Use your own crop name", "ලැයිස්තුවේ නැතිද? ඔබේම බෝග නම භාවිතා කරන්න")),
                      onTap: () => Navigator.pop(context, _titleCase(query)),
                    ),
                  if (showYourCrops) ...[
                    _sectionHeader(_s("YOUR CROPS", "ඔබේ බෝග")),
                    ...widget.yourCrops.map(_yourCropTile),
                  ],
                  _sectionHeader(query.isEmpty ? _s("ALL CROPS", "සියලුම බෝග") : _s("RESULTS", "ප්‍රතිඵල")),
                  if (results.isEmpty && !showCustomOption)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text(_s("No crop found", "බෝගයක් හමු නොවීය"))),
                    ),
                  ...results.map(_cropTile),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
