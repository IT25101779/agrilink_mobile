import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../localization/app_locale.dart';

class DiseaseScannerScreen extends StatefulWidget {
  final String? prefilledCropType;
  final String? reminderId;

  const DiseaseScannerScreen({super.key, this.prefilledCropType, this.reminderId});

  @override
  State<DiseaseScannerScreen> createState() => _DiseaseScannerScreenState();
}

class _DiseaseScannerScreenState extends State<DiseaseScannerScreen> {
  final _cropController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  bool _isScanning = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCropType != null) {
      _cropController.text = widget.prefilledCropType!;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1024, imageQuality: 80);
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _result = null;
      _errorMessage = null;
    });
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        if (requested == LocationPermission.denied || requested == LocationPermission.deniedForever) {
          return null;
        }
      }
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<void> _scanImage() async {
    if (_imageBytes == null) {
      setState(() => _errorMessage = "Please take or upload a photo first.");
      return;
    }
    if (_cropController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter the crop type.");
      return;
    }

    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _result = null;
    });

    final farmerId = await AuthService.getUserId() ?? "";
    final position = await _getCurrentLocation();

    // Falls back to a default Sri Lankan coordinate if GPS permission is
    // denied (e.g. running in a browser without location access granted).
    final latitude = position?.latitude ?? 7.2906;
    final longitude = position?.longitude ?? 80.6337;

    final base64Image = "data:image/jpeg;base64,${base64Encode(_imageBytes!)}";

    final result = await ApiService.scanCropDisease(
      farmerId: farmerId,
      cropType: _cropController.text.trim(),
      imageBase64: base64Image,
      latitude: latitude,
      longitude: longitude,
    );

    setState(() {
      _isScanning = false;
      if (result["success"] == true) {
        _result = result["data"];
      } else {
        _errorMessage = result["message"] ?? "Scan failed. Please try again.";
      }
    });

    // If this scan was triggered from a "please send a photo" reminder,
    // mark that reminder as fulfilled and link it to the resulting scan.
    if (widget.reminderId != null && result["success"] == true) {
      final diseaseLogId = result["data"]?["diseaseLogId"];
      await ApiService.updateReminder(
        reminderId: widget.reminderId!,
        status: "photo_submitted",
        linkedDiseaseLogId: diseaseLogId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t("scanCropForDisease"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            t("scanCropSubtitle"),
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (widget.reminderId != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Expanded(child: Text("Responding to a reminder — this photo will be linked automatically.", style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _cropController,
            decoration: InputDecoration(labelText: t("cropTypeHint"), border: const OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          if (_imageBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_imageBytes!, height: 220, width: double.infinity, fit: BoxFit.cover),
            )
          else
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.photo_camera_outlined, size: 48, color: Colors.grey)),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: Text(t("camera")),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: Text(t("gallery")),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _scanImage,
              icon: const Icon(Icons.biotech),
              label: _isScanning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(t("diagnose")),
              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
              child: Text(_errorMessage!, style: TextStyle(color: Colors.red[700])),
            ),
          ],
          if (_result != null) ..._buildResultCards(_result!),
        ],
      ),
    );
      },
    );
  }

  List<Widget> _buildResultCards(Map<String, dynamic> result) {
    if (result["healthy"] == true) {
      return [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Expanded(child: Text("No disease detected. Your crop looks healthy!")),
            ],
          ),
        ),
      ];
    }

    final disease = result["detectedDisease"] ?? "Unknown";
    final confidence = ((result["confidenceScore"] ?? 0) * 100).toStringAsFixed(1);
    final severity = result["severity"];
    final treatment = result["treatment"] as Map<String, dynamic>?;
    final outbreak = result["outbreakAlert"] as Map<String, dynamic>?;

    return [
      const SizedBox(height: 16),
      Card(
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(disease, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Chip(label: Text("$confidence% match")),
                ],
              ),
              if (severity != null) ...[
                const SizedBox(height: 6),
                Text("Severity: $severity", style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
      if (treatment != null) ...[
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Recommended treatment", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...treatment.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      "${entry.key[0].toUpperCase()}${entry.key.substring(1)}: ${(entry.value is List) ? (entry.value as List).join(", ") : entry.value}",
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      if (outbreak != null) ...[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red[200]!)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.campaign, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Regional Outbreak Alert", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 6),
              Text(outbreak["message"] ?? "", style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    ];
  }
}
