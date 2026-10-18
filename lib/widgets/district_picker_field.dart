import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../localization/chat_labels.dart';
import '../theme/app_theme.dart';

bool _isSinhala() => AppLocale.instance.languageCode == "si";
String _s(String en, String si) => _isSinhala() ? si : en;

/// A district selector that looks like a normal text field but opens a
/// searchable list of all 25 districts when tapped, instead of either a
/// long plain dropdown or free text that might not match the server's
/// spelling exactly. Same pattern as [CropPickerField] (see that file).
class DistrictPickerField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String>? onSelected;
  final String? Function(String?)? validator;

  const DistrictPickerField({
    super.key,
    required this.controller,
    required this.label,
    this.onSelected,
    this.validator,
  });

  Future<void> _openPicker(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _DistrictPickerSheet(currentValue: controller.text),
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
        prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
        suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
      ),
    );
  }
}

class _DistrictPickerSheet extends StatefulWidget {
  final String currentValue;
  const _DistrictPickerSheet({required this.currentValue});

  @override
  State<_DistrictPickerSheet> createState() => _DistrictPickerSheetState();
}

class _DistrictPickerSheetState extends State<_DistrictPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final results = query.isEmpty ? kChatDistricts : kChatDistricts.where((d) => d.toLowerCase().contains(query)).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: _s("Search district", "දිස්ත්‍රික්කය සොයන්න"),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Expanded(
              child: results.isEmpty
                  ? Center(child: Text(_s("No district found", "දිස්ත්‍රික්කයක් හමු නොවීය")))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final d = results[i];
                        final selected = d.toLowerCase() == widget.currentValue.trim().toLowerCase();
                        return ListTile(
                          leading: const Icon(Icons.location_on_outlined, color: AppColors.forest),
                          title: Text(d, style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.forest) : null,
                          onTap: () => Navigator.pop(context, d),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
