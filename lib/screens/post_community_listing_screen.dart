import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../localization/app_locale.dart';
import '../localization/tr.dart';

class PostCommunityListingScreen extends StatefulWidget {
  const PostCommunityListingScreen({super.key});

  @override
  State<PostCommunityListingScreen> createState() => _PostCommunityListingScreenState();
}

class _PostCommunityListingScreenState extends State<PostCommunityListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceAmountController = TextEditingController();
  final _priceUnitController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _districtController = TextEditingController();

  String _listingType = "equipment_rental";
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _prefillDistrict();
  }

  Future<void> _prefillDistrict() async {
    final district = await AuthService.getDistrict();
    if (district != null && district.trim().isNotEmpty) {
      setState(() => _districtController.text = district);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    Position? position;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.deniedForever) {
        position = await Geolocator.getCurrentPosition();
      }
    } catch (_) {}

    final farmerId = await AuthService.getUserId() ?? "";
    final latitude = position?.latitude ?? 7.2906;
    final longitude = position?.longitude ?? 80.6337;

    final result = await ApiService.createCommunityListing(
      farmerId: farmerId,
      listingType: _listingType,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priceAmount: double.parse(_priceAmountController.text),
      priceUnit: _priceUnitController.text.trim(),
      latitude: latitude,
      longitude: longitude,
      district: _districtController.text.trim(),
      contactPhone: _contactPhoneController.text.trim().isEmpty ? null : _contactPhoneController.text.trim(),
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (result["success"] == true) {
      Navigator.pop(context, true);
    } else {
      setState(() => _errorMessage = result["message"] ?? "Failed to post listing.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return Scaffold(
          appBar: AppBar(title: Text(t("postAnItem"))),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: "equipment_rental", label: Text(t("equipmentRental"), style: const TextStyle(fontSize: 11.5))),
                      ButtonSegment(value: "seeds_for_sale", label: Text(t("seedsForSale"), style: const TextStyle(fontSize: 11.5))),
                      ButtonSegment(value: "other", label: Text(t("otherItem"), style: const TextStyle(fontSize: 11.5))),
                    ],
                    selected: {_listingType},
                    onSelectionChanged: (selection) => setState(() => _listingType = selection.first),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: t("itemTitle"), border: const OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(labelText: t("itemDescription"), border: const OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceAmountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: t("priceAmount"), border: const OutlineInputBorder()),
                          validator: (v) => (v == null || double.tryParse(v) == null) ? "Enter a number" : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _priceUnitController,
                          decoration: InputDecoration(labelText: t("priceUnit"), border: const OutlineInputBorder()),
                          validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _districtController,
                    decoration: InputDecoration(labelText: t("district"), border: const OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty) ? "Required" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: t("contactPhoneLabel"),
                      helperText: tr("Leave blank to use your account's phone number", "ඔබගේ ගිණුමේ දුරකථන අංකය භාවිත කිරීමට හිස්ව තබන්න", "உங்கள் கணக்கின் தொலைபேசி எண்ணைப் பயன்படுத்த வெறுமையாக விடுங்கள்"),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(t("postListing")),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
