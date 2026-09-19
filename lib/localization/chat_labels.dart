import 'package:flutter/material.dart';
import '../services/crop_recommendation_service.dart';
import 'crop_names.dart';
import 'tr.dart';

/// The 25 districts, spelled exactly as the server expects them.
const List<String> kChatDistricts = [
  "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo", "Galle", "Gampaha", "Hambantota", "Jaffna",
  "Kalutara", "Kandy", "Kegalle", "Kilinochchi", "Kurunegala", "Mannar", "Matale", "Matara", "Monaragala",
  "Mullaitivu", "Nuwara Eliya", "Polonnaruwa", "Puttalam", "Ratnapura", "Trincomalee", "Vavuniya",
];

String _cropLabel(String? englishName) {
  if (englishName == null) return "";
  for (final crop in CropRecommendationService.catalogue) {
    if (crop.name == englishName) return cropLocalName(crop);
  }
  return englishName;
}

/// "Kandy farmers", "Tomato growers", "Tomato · Kandy", "All farmers" — in the farmer's language.
String groupTitle(Map<dynamic, dynamic> group) {
  final district = "${group["district"] ?? ""}";
  final crop = _cropLabel(group["crop"] as String?);
  switch (group["scope"]) {
    case "all":
      return tr("All farmers", "සියලුම ගොවීන්", "அனைத்து விவசாயிகளும்");
    case "district":
      return tr("$district farmers", "$district ගොවීන්", "$district விவசாயிகள்");
    case "crop":
      return tr("$crop growers", "$crop වගාකරුවන්", "$crop பயிரிடுவோர்");
    default:
      return "$crop · $district";
  }
}

String groupSubtitle(Map<dynamic, dynamic> group) {
  switch (group["scope"]) {
    case "all":
      return tr("Everyone in Sri Lanka", "ශ්‍රී ලංකාවේ සියලුම දෙනා", "இலங்கை முழுவதும் அனைவரும்");
    case "district":
      return tr("Farmers from this area", "මෙම ප්‍රදේශයේ ගොවීන්", "இந்தப் பகுதி விவசாயிகள்");
    case "crop":
      return tr("Farmers growing this crop", "මෙම බෝගය වගා කරන ගොවීන්", "இந்தப் பயிரை வளர்க்கும் விவசாயிகள்");
    default:
      return tr("This crop, this area", "මෙම බෝගය, මෙම ප්‍රදේශය", "இந்தப் பயிர், இந்தப் பகுதி");
  }
}

IconData groupIcon(String? scope) {
  switch (scope) {
    case "all":
      return Icons.public_rounded;
    case "district":
      return Icons.place_rounded;
    case "crop":
      return Icons.grass_rounded;
    default:
      return Icons.pin_drop_rounded;
  }
}

Color groupColor(String? scope) {
  switch (scope) {
    case "all":
      return const Color(0xFF2563EB);
    case "district":
      return const Color(0xFF0D9488);
    case "crop":
      return const Color(0xFF16A34A);
    default:
      return const Color(0xFFEA580C);
  }
}

/// A friendly, translated explanation for the reason code the server sends back.
String chatErrorText(String? code, String fallback) {
  switch (code) {
    case "phone":
      return tr("Please don't share phone numbers here. This chat is anonymous and safe.", "කරුණාකර මෙහි දුරකථන අංක බෙදා නොගන්න. මෙම කතාබහ නිර්නාමික සහ ආරක්ෂිතයි.", "தயவுசெய்து இங்கே தொலைபேசி எண்களைப் பகிர வேண்டாம். இந்த உரையாடல் பெயர் தெரியாதது, பாதுகாப்பானது.");
    case "email":
      return tr("Please don't share email addresses here.", "කරුණාකර මෙහි ඊමේල් ලිපිනයන් බෙදා නොගන්න.", "தயவுசெய்து இங்கே மின்னஞ்சல் முகவரிகளைப் பகிர வேண்டாம்.");
    case "link":
      return tr("Links and websites can't be shared in this chat.", "මෙම කතාබහේ සබැඳි සහ වෙබ් අඩවි බෙදා ගත නොහැක.", "இந்த உரையாடலில் இணைப்புகளையும் இணையதளங்களையும் பகிர முடியாது.");
    case "profanity":
      return tr("Please keep the chat respectful. That message has words that aren't allowed.", "කරුණාකර කතාබහ ගෞරවනීය ලෙස තබාගන්න. එම පණිවිඩයේ ඉඩ නොදෙන වචන ඇත.", "உரையாடலை மரியாதையாக வையுங்கள். அந்தச் செய்தியில் அனுமதிக்கப்படாத சொற்கள் உள்ளன.");
    case "spam":
      return tr("That looks like spam. Please write a normal message.", "එය ස්පෑම් ලෙස පෙනේ. කරුණාකර සාමාන්‍ය පණිවිඩයක් ලියන්න.", "அது ஸ்பேம் போல் உள்ளது. சாதாரணச் செய்தியை எழுதுங்கள்.");
    case "rate_limited":
      return tr("You are sending messages very fast. Please wait a moment.", "ඔබ ඉතා වේගයෙන් පණිවිඩ යවයි. කරුණාකර මොහොතක් රැඳී සිටින්න.", "நீங்கள் மிக வேகமாகச் செய்திகளை அனுப்புகிறீர்கள். சற்றுக் காத்திருங்கள்.");
    case "banned":
      return tr("You can't post in chats right now.", "ඔබට දැනට කතාබහ වල පළ කළ නොහැක.", "இப்போது உரையாடல்களில் பதிவிட உங்களால் முடியாது.");
    case "too_large":
      return tr("That file is too large. Please choose a smaller photo or a shorter voice message.", "එම ගොනුව විශාල වැඩියි. කුඩා ඡායාරූපයක් හෝ කෙටි හඬ පණිවිඩයක් තෝරන්න.", "அந்தக் கோப்பு மிகப் பெரியது. சிறிய படம் அல்லது குறுகிய குரல் செய்தியைத் தேர்ந்தெடுங்கள்.");
    case "bad_format":
      return tr("That file type isn't supported.", "එම ගොනු වර්ගයට සහාය නොදක්වයි.", "அந்தக் கோப்பு வகை ஆதரிக்கப்படவில்லை.");
    case "too_long":
      return tr("Voice messages can be at most 90 seconds.", "හඬ පණිවිඩ උපරිම තත්පර 90 කි.", "குரல் செய்திகள் அதிகபட்சம் 90 விநாடிகள்.");
    default:
      return fallback;
  }
}
