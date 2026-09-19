import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/crop_picker_field.dart';
import '../widgets/ui_kit.dart';
import '../localization/tr.dart';

class DiseaseScannerScreen extends StatefulWidget {
  final String? prefilledCropType;
  final String? reminderId;
  // True when this screen is one of Home's bottom-nav tabs (Home already
  // provides the Scaffold + AppBar in that case). False when it's pushed
  // as its own full-screen route — e.g. from a disease reminder's
  // "Upload Photo" button — where it needs its own AppBar with a back
  // button, since nothing else on screen would otherwise let the farmer
  // navigate back (this was the missing-back-button bug).
  final bool embedded;

  const DiseaseScannerScreen({
    super.key,
    this.prefilledCropType,
    this.reminderId,
    this.embedded = true,
  });

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
    } else {
      _prefillFromActiveTimeline();
    }
  }

  /// If the farmer is already growing something, start with that crop
  /// selected — one less thing to do in the field. They can still change it.
  Future<void> _prefillFromActiveTimeline() async {
    final crops = await CropPickerField.activeCropNames();
    if (!mounted || crops.isEmpty || _cropController.text.isNotEmpty) return;
    setState(() => _cropController.text = crops.first);
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
      setState(() => _errorMessage = tr("Please take or upload a photo first.", "කරුණාකර මුලින්ම ඡායාරූපයක් ගන්න හෝ උඩුගත කරන්න.", "முதலில் ஒரு புகைப்படம் எடுக்கவும் அல்லது பதிவேற்றவும்."));
      return;
    }
    if (_cropController.text.trim().isEmpty) {
      setState(() => _errorMessage = tr("Please select the crop.", "කරුණාකර බෝගය තෝරන්න.", "பயிரைத் தேர்ந்தெடுக்கவும்."));
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
      // Requests the result translated server-side into whatever language
      // the farmer currently has selected — the disease name, severity,
      // symptoms, and treatment text all come back pre-translated.
      language: AppLocale.instance.languageCode,
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

  /// Builds a plain-text version of the current result, suitable for
  /// text-to-speech readout — same content shown on screen, without the
  /// visual formatting.
  String _resultAsSpeech(Map<String, dynamic> result) {
    final t = AppLocale.instance.t;
    if (result["healthy"] == true) {
      return t("healthyCrop");
    }
    final buffer = StringBuffer();
    buffer.write(result["detectedDisease"] ?? "");
    final severity = result["severity"];
    if (severity != null) {
      buffer.write(". ${t("severityLabel")}: $severity");
    }
    final treatment = result["treatment"];
    if (treatment is Map) {
      buffer.write(". ${t("recommendedTreatmentLabel")}: ");
      buffer.write(treatment.values.whereType<String>().join(". "));
    } else if (treatment is String) {
      buffer.write(". ${t("recommendedTreatmentLabel")}: $treatment");
    }
    final outbreak = result["outbreakAlert"];
    if (outbreak is Map && outbreak["message"] != null) {
      buffer.write(". ${outbreak["message"]}");
    }
    return buffer.toString();
  }

  Widget _buildContent() {
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
              child: Row(
                children: [
                  Icon(Icons.notifications_active_rounded, size: 16, color: Color(0xFF4F46E5)),
                  SizedBox(width: 8),
                  Expanded(child: Text(tr("Responding to a reminder — this photo will be linked automatically.", "මතක් කිරීමකට පිළිතුරු දෙමින් — මෙම ඡායාරූපය ස්වයංක්‍රීයව සම්බන්ධ වේ.", "நினைவூட்டலுக்குப் பதிலளிக்கிறீர்கள் — இந்தப் புகைப்படம் தானாக இணைக்கப்படும்."), style: TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          CropPickerField(
            controller: _cropController,
            label: tr("Select crop", "බෝගය තෝරන්න", "பயிரைத் தேர்ந்தெடுக்கவும்"),
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
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: tintOf(context, AppColors.forest),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.forest.withOpacity(0.35), width: 1.4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_camera_rounded, size: 44, color: AppColors.forest),
                  const SizedBox(height: 10),
                  Text(tr("Add a photo of the affected leaf", "රෝගී කොළයේ ඡායාරූපයක් එක් කරන්න", "பாதிக்கப்பட்ட இலையின் புகைப்படத்தைச் சேர்க்கவும்"),
                      textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    tr("Tip: one leaf, close-up, in daylight, in focus.", "ඉඟිය: එක් කොළයක්, සමීපව, දහවල් එළියේ, පැහැදිලිව.", "குறிப்பு: ஒரு இலை, நெருக்கமாக, பகல் வெளிச்சத்தில், தெளிவாக."),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: mutedOf(context), height: 1.4),
                  ),
                ],
              ),
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
              decoration: BoxDecoration(color: tintOf(context, AppColors.danger), borderRadius: BorderRadius.circular(10)),
              child: Text(_errorMessage!, style: const TextStyle(color: AppColors.danger)),
            ),
          ],
          if (_result != null) ..._buildResultCards(_result!),
        ],
      ),
    );
      },
    );
  }

  /// Colours the severity by keyword (works for the English and Sinhala words the server returns).
  Color _severityColor(String? severity) {
    final v = (severity ?? "").toLowerCase();
    if (v.contains("sever") || v.contains("high") || v.contains("දරුණු") || v.contains("ඉහළ")) return AppColors.danger;
    if (v.contains("moder") || v.contains("medium") || v.contains("මධ්‍යම")) return const Color(0xFFE67E22);
    if (v.contains("mild") || v.contains("low") || v.contains("සුළු") || v.contains("අඩු")) return AppColors.gold;
    return const Color(0xFFE67E22);
  }

  IconData _treatmentIcon(String key) {
    final k = key.toLowerCase();
    if (k.contains("chem")) return Icons.science_rounded;
    if (k.contains("bio") || k.contains("organic")) return Icons.eco_rounded;
    if (k.contains("prevent")) return Icons.shield_rounded;
    return Icons.healing_rounded;
  }

  Color _treatmentColor(String key) {
    final k = key.toLowerCase();
    if (k.contains("chem")) return AppColors.indigo;
    if (k.contains("bio") || k.contains("organic")) return AppColors.forest;
    if (k.contains("prevent")) return AppColors.gold;
    return AppColors.inkMuted;
  }

  Widget _treatmentSection(String key, dynamic value) {
    final color = _treatmentColor(key);
    final items = value is List ? value.map((e) => "$e").toList() : ["$value"];
    final title = key.isEmpty ? "" : "${key[0].toUpperCase()}${key.substring(1)}";
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: tintOf(context, color), borderRadius: BorderRadius.circular(9)),
                child: Icon(_treatmentIcon(key), size: 17, color: color),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 8),
                    child: Icon(Icons.circle, size: 5, color: color),
                  ),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 13.5, height: 1.4))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResultCards(Map<String, dynamic> result) {
    final t = AppLocale.instance.t;

    // Speaker button shown on every result variant (healthy or not) so the
    // farmer can hear the outcome read aloud.
    Widget readAloudButton(Color color) => IconButton(
          icon: Icon(Icons.volume_up_rounded, color: color),
          tooltip: t("readAloud"),
          onPressed: () => VoiceService.speak(_resultAsSpeech(result)),
        );

    if (result["healthy"] == true) {
      return [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.forestDark, AppColors.forest], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(t("healthyCrop"), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5, height: 1.35))),
              readAloudButton(Colors.white),
            ],
          ),
        ),
      ];
    }

    final disease = result["detectedDisease"] ?? "Unknown";
    final confidenceValue = (result["confidenceScore"] as num?)?.toDouble() ?? 0.0;
    final confidence = (confidenceValue * 100).toStringAsFixed(1);
    final severity = result["severity"]?.toString();
    final severityColor = _severityColor(severity);
    // The server normally sends treatment as a map (chemical / biological /
    // prevention), but can send plain text. Handle both instead of crashing.
    final rawTreatment = result["treatment"];
    final Map<String, dynamic>? treatment = rawTreatment is Map ? Map<String, dynamic>.from(rawTreatment) : null;
    final String? treatmentText = rawTreatment is String && rawTreatment.trim().isNotEmpty ? rawTreatment : null;
    final outbreak = result["outbreakAlert"] as Map<String, dynamic>?;

    return [
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tintOf(context, severityColor),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: severityColor.withOpacity(0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: severityColor.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.bug_report_rounded, color: severityColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr("Diagnosis", "රෝග විනිශ්චය", "நோய் கண்டறிதல்"), style: TextStyle(fontSize: 11.5, color: mutedOf(context), fontWeight: FontWeight.w700)),
                      Text("$disease", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, height: 1.2)),
                    ],
                  ),
                ),
                readAloudButton(AppColors.forest),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: RoundedBar(value: confidenceValue, color: severityColor, height: 9)),
                const SizedBox(width: 10),
                Text("$confidence% ${tr("match", "ගැලපීම", "பொருத்தம்")}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5)),
              ],
            ),
            if (severity != null && severity.isNotEmpty) ...[
              const SizedBox(height: 10),
              StatusPill(label: "${t("severityLabel")}: $severity", color: severityColor, icon: Icons.flag_rounded),
            ],
          ],
        ),
      ),
      if (result["lowConfidence"] == true) ...[
        const SizedBox(height: 10),
        InfoBanner(
          icon: Icons.info_outline_rounded,
          color: AppColors.gold,
          text: tr("This result has low confidence. Please retake a clearer, close-up photo of the affected leaf and try again.", "මෙම ප්‍රතිඵලය අඩු විශ්වාසයකින් යුක්තයි. කරුණාකර රෝග ඇති කොළයේ වඩාත් පැහැදිලි, සමීප ඡායාරූපයක් ගෙන නැවත උත්සාහ කරන්න.", "இந்த முடிவின் நம்பகத்தன்மை குறைவு. பாதிக்கப்பட்ட இலையின் தெளிவான, நெருக்கமான புகைப்படத்தை எடுத்து மீண்டும் முயற்சிக்கவும்."),
        ),
      ],
      if (treatmentText != null || (treatment != null && treatment.isNotEmpty)) ...[
        const SizedBox(height: 14),
        Text(t("recommendedTreatmentLabel"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5)),
        const SizedBox(height: 8),
      ],
      if (treatmentText != null) _treatmentSection("", treatmentText),
      if (treatment != null) ...treatment.entries.map((entry) => _treatmentSection(entry.key, entry.value)),
      if (outbreak != null) ...[
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tintOf(context, AppColors.danger),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.danger.withOpacity(0.4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.campaign_rounded, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t("regionalOutbreakAlertLabel"), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.danger)),
                    const SizedBox(height: 4),
                    Text(outbreak["message"] ?? "", style: const TextStyle(fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 90),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // Home tab context — Home's own Scaffold + AppBar already wraps this.
      return _buildContent();
    }

    // Pushed as a standalone route (e.g. from a Reminder's "Upload Photo"
    // button) — needs its own AppBar with a back button, since there's
    // nothing else on screen that would let the farmer navigate back.
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: Text(AppLocale.instance.t("diseaseScanner"))),
          body: _buildContent(),
        );
      },
    );
  }
}
