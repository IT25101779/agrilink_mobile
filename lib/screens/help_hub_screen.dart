import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../widgets/farm_common.dart';
import '../widgets/feedback_sheet.dart';
import '../widgets/ui_kit.dart';
import 'ask_officer_screen.dart';
import 'damage_screen.dart';
import 'offices_screen.dart';
import 'pest_library_screen.dart';
import 'rain_planner_screen.dart';
import 'records_screen.dart';
import 'settings_screen.dart';
import 'wildlife_screen.dart';

/// One place for the "reliable in Sri Lanka" tools.
class HelpHubScreen extends StatelessWidget {
  const HelpHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget p) => Navigator.push(context, MaterialPageRoute(builder: (_) => p));
    Widget tile(IconData icon, Color c, String title, String sub, VoidCallback onTap) => SoftCard(
          onTap: onTap,
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: tintOf(context, c), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: c)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)), Text(sub, style: const TextStyle(fontSize: 12), maxLines: 2)])),
            const Icon(Icons.chevron_right_rounded),
          ]),
        );
    return Scaffold(
      appBar: AppBar(title: Text(tr("Help & safety", "උපකාර හා ආරක්ෂාව", "உதவி & பாதுகாப்பு"))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
        tile(Icons.pets_rounded, const Color(0xFF92400E), tr("Wildlife alerts", "සත්ව අනතුරු ඇඟවීම්", "வனவிலங்கு எச்சரிக்கை"), tr("Warn neighbours about elephants, boar, monkeys", "අලි, වල් ඌරන්, වඳුරන් ගැන අසල්වැසියන්ට අනතුරු අඟවන්න", "யானை, பன்றி, குரங்கு பற்றி அண்டையாருக்கு எச்சரிக்கை"), () => open(const WildlifeScreen())),
        tile(Icons.support_agent_rounded, const Color(0xFF0B5D3B), tr("Ask an officer", "නිලධාරියෙකුගෙන් අසන්න", "அலுவலரிடம் கேளுங்கள்"), tr("Send a question to your district's officer", "ඔබේ දිස්ත්‍රික්ක නිලධාරියාට ප්‍රශ්නයක් යවන්න", "உங்கள் மாவட்ட அலுவலருக்கு கேள்வி அனுப்பு"), () => open(const AskOfficerScreen())),
        tile(Icons.menu_book_rounded, const Color(0xFFB45309), tr("Pest & disease guide", "පළිබෝධ හා රෝග මාර්ගෝපදේශය", "பூச்சி & நோய் வழிகாட்டி"), tr("Works without internet", "අන්තර්ජාලයෙන් තොරව ක්‍රියා කරයි", "இணையம் இல்லாமல் செயல்படும்"), () => open(const PestLibraryScreen())),
        tile(Icons.water_drop_rounded, const Color(0xFF0E7490), tr("Rain & planting planner", "වැසි හා වගා සැලසුම", "மழை & நடவு திட்டம்"), tr("When to plant for Maha and Yala", "මහ හා යල සඳහා වගා කාලය", "பெரும்போகம், சிறுபோகத்திற்கு எப்போது நடவு"), () => open(const RainPlannerScreen())),
        tile(Icons.agriculture_rounded, const Color(0xFF7C3AED), tr("My harvests & support", "මගේ අස්වැන්න හා සහනාධාර", "எனது அறுவடை & உதவி"), tr("kg per acre, fertilizer subsidy, lender report", "අක්කරයට කි.ග්‍රෑ, පොහොර සහනාධාරය, ණය වාර්තාව", "ஏக்கருக்கு கிலோ, உர மானியம், கடன் அறிக்கை"), () => open(const RecordsScreen())),
        tile(Icons.storm_rounded, const Color(0xFFB91C1C), tr("Crop damage reports", "බෝග හානි වාර්තා", "பயிர் சேத அறிக்கைகள்"), tr("Photos and details for an insurer or officer", "රක්ෂණ ආයතනයක් හෝ නිලධාරියෙකු සඳහා ඡායාරූප හා විස්තර", "காப்பீட்டாளர்/அலுவலருக்கு படங்களும் விவரங்களும்"), () => open(const DamageScreen())),
        tile(Icons.location_city_rounded, const Color(0xFF2563EB), tr("Get help near me", "ආසන්න උපකාර", "அருகில் உதவி"), tr("Agrarian Service Centre, cooperatives", "ගොවිජන සේවා මධ්‍යස්ථාන, සමුපකාර", "விவசாய சேவை மையம், கூட்டுறவு"), () => open(const OfficesScreen())),
        tile(Icons.settings_rounded, const Color(0xFF475569), tr("Settings & privacy", "සැකසුම් හා රහස්‍යතාව", "அமைப்புகள் & தனியுரிமை"), tr("Low-data, simple mode, SMS, your data", "අඩු දත්ත, සරල ප්‍රකාරය, SMS, ඔබේ දත්ත", "குறைந்த தரவு, எளிய முறை, SMS, உங்கள் தரவு"), () => open(const SettingsScreen())),
        tile(Icons.feedback_rounded, const Color(0xFF059669), tr("Tell us what to improve", "වැඩි දියුණු කළ යුතු දේ කියන්න", "எதை மேம்படுத்த வேண்டும்"), tr("Report a problem or an idea", "ගැටලුවක් හෝ අදහසක් වාර්තා කරන්න", "பிரச்சினை/யோசனையைத் தெரிவிக்கவும்"), () => showFeedbackSheet(context, screen: "help_hub")),
      ]),
    );
  }
}
