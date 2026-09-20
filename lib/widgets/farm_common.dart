import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/crop_names.dart';
import '../localization/tr.dart';
import '../services/crop_recommendation_service.dart';

/// English crop name -> the name in the farmer's language.
String cropLabel(String english) {
  for (final crop in CropRecommendationService.catalogue) {
    if (crop.name == english) return cropLocalName(crop);
  }
  return english;
}

/// Every crop name (English), sorted — used by dropdowns.
List<String> allCropNames() => (CropRecommendationService.catalogue.map((c) => c.name).toList()..sort());

String hubName(String hub) {
  switch (hub) {
    case "Dambulla":
      return tr("Dambulla", "දඹුල්ල", "தம்புள்ளை");
    case "Colombo_Manning_Market":
    case "Manning":
      return tr("Manning Market", "මැනිං වෙළඳපොළ", "மானிங் சந்தை");
    case "Pettah":
      return tr("Pettah", "පිටකොටුව", "புறக்கோட்டை");
    case "Kandy":
      return tr("Kandy", "මහනුවර", "கண்டி");
    case "Jaffna":
      return tr("Jaffna", "යාපනය", "யாழ்ப்பாணம்");
    case "Meegoda":
      return tr("Meegoda", "මීගොඩ", "மீகொடை");
    case "Narahenpita":
      return tr("Narahenpita", "නාරාහේන්පිට", "நாரஹேன்பிட்டி");
    case "Thambuttegama":
      return tr("Thambuttegama", "තඹුත්තේගම", "தம்புத்தேகம");
    default:
      return hub.replaceAll("_", " ");
  }
}

const List<String> kTruckHubs = ["Dambulla", "Colombo_Manning_Market", "Pettah", "Kandy", "Jaffna", "Other"];

/// "Tue 22 Sep, 05:30"
String whenText(String? iso) {
  final d = DateTime.tryParse(iso ?? "")?.toLocal();
  if (d == null) return "";
  const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  final hh = d.hour.toString().padLeft(2, "0"), mm = d.minute.toString().padLeft(2, "0");
  return "${days[d.weekday - 1]} ${d.day} ${months[d.month - 1]}, $hh:$mm";
}

Future<void> callPhone(String phone) async {
  final uri = Uri(scheme: "tel", path: phone.replaceAll(" ", ""));
  if (await canLaunchUrl(uri)) await launchUrl(uri);
}

void showSnack(BuildContext context, String text) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

/// The message the server sent, or a simple fallback.
String apiMessage(Map<String, dynamic> result, [String? fallback]) =>
    "${result["message"] ?? fallback ?? tr("Something went wrong. Please try again.", "යම් දෙයක් වැරදුණා. නැවත උත්සාහ කරන්න.", "ஏதோ தவறு நடந்தது. மீண்டும் முயற்சிக்கவும்.")}";

Widget emptyState(IconData icon, String title, String subtitle) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 30),
      child: Column(children: [
        Icon(icon, size: 54, color: Colors.grey.shade400),
        const SizedBox(height: 14),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
      ]),
    );
