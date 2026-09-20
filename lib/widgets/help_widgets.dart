import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import '../services/voice_service.dart';
import '../theme/app_theme.dart';

/// Takes or picks a photo and returns it as base64, small enough for the server (300 KB limit).
/// Returns null if the person cancels, "TOO_BIG" if it could not be made small enough.
Future<String?> pickPhotoBase64(BuildContext context, {bool camera = true}) async {
  final file = await ImagePicker().pickImage(source: camera ? ImageSource.camera : ImageSource.gallery, maxWidth: 900, maxHeight: 900, imageQuality: 45);
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  return bytes.length <= 280 * 1024 ? base64Encode(bytes) : "TOO_BIG";
}

/// Choose camera or gallery, then pick.
Future<String?> askAndPickPhoto(BuildContext context) async {
  final camera = await showModalBottomSheet<bool>(
    context: context,
    builder: (_) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.photo_camera_rounded), title: Text(tr("Take a photo", "ඡායාරූපයක් ගන්න", "புகைப்படம் எடுக்கவும்")), onTap: () => Navigator.pop(context, true)),
        ListTile(leading: const Icon(Icons.photo_library_rounded), title: Text(tr("Choose from gallery", "ගැලරියෙන් තෝරන්න", "கேலரியிலிருந்து தேர்வு")), onTap: () => Navigator.pop(context, false)),
      ]),
    ),
  );
  if (camera == null || !context.mounted) return null;
  return pickPhotoBase64(context, camera: camera);
}

/// A small "read this aloud" button (uses the phone's voice, in the language chosen).
class SpeakButton extends StatelessWidget {
  final String text;
  const SpeakButton({super.key, required this.text});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: tr("Read aloud", "කියවන්න", "வாசிக்கவும்"),
        icon: const Icon(Icons.volume_up_rounded, color: AppColors.forest),
        onPressed: () => VoiceService.speak(text),
      );
}

const Map<String, String> kSpeciesEmoji = {"elephant": "🐘", "wild_boar": "🐗", "monkey": "🐒", "peacock": "🦚", "porcupine": "🦔", "other": "🐾"};

String speciesLabel(String s) {
  switch (s) {
    case "elephant":
      return tr("Elephants", "අලි", "யானைகள்");
    case "wild_boar":
      return tr("Wild boar", "වල් ඌරන්", "காட்டுப்பன்றி");
    case "monkey":
      return tr("Monkeys", "වඳුරන්", "குரங்குகள்");
    case "peacock":
      return tr("Peacocks", "මොනරුන්", "மயில்கள்");
    case "porcupine":
      return tr("Porcupines", "ඌ ", "முள்ளம்பன்றி");
    default:
      return tr("Other animals", "වෙනත් සතුන්", "பிற விலங்குகள்");
  }
}

/// The government guaranteed / support prices the AgriLink team has published from official notices.
Future<void> showSupportPricesSheet(BuildContext context) async {
  final r = await HelpApi.supportPrices();
  if (!context.mounted) return;
  final rows = r["success"] == true ? (r["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList() : <Map<String, dynamic>>[];
  await showModalBottomSheet(
    context: context,
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr("Guaranteed prices", "සහතික මිල", "உத்தரவாத விலைகள்"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 8),
          if (rows.isEmpty) Text(tr("No guaranteed prices published right now.", "දැනට සහතික මිල ප්‍රකාශයට පත් කර නැත.", "இப்போது உத்தரவாத விலைகள் இல்லை."), style: const TextStyle(color: AppColors.inkMuted)),
          ...rows.map((p) => ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text("${p["cropType"]}${"${p["label"]}".isEmpty ? "" : " - ${p["label"]}"}", style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text("${p["source"]}".isEmpty ? "" : "${p["source"]}"), trailing: Text("LKR ${p["pricePerKg"]}/kg", style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.forest)))),
        ]),
      ),
    ),
  );
}
