import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../theme/app_theme.dart';
import '../screens/offices_screen.dart';
import 'farm_common.dart';
import 'smooth_route.dart';
import 'ui_kit.dart';

/// AgriLink's own support line — a human the farmer can reach directly if an
/// AI result looks wrong or they just want a second opinion.
///
/// TODO(team): replace with the real AgriLink/Govi Tech support number
/// before this ships — this placeholder must not go out in the submitted
/// build or the final presentation.
const String kAgriLinkSupportPhone = "+94 00 000 0000";

/// Shown on every screen where the app gives a recommendation the farmer
/// might act on (Disease Scanner diagnosis, Crop Navigator suggestions) —
/// a plain-language accuracy disclaimer plus two one-tap ways to reach a
/// real human: the farmer's own district agricultural officer (via the
/// existing Offices directory, district-matched, with call buttons already
/// built in), or AgriLink's own support line.
class AiAdviceDisclaimer extends StatelessWidget {
  const AiAdviceDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tintOf(context, AppColors.gold),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tr(
                    "These recommendations are AI-assisted and not 100% accurate. If you have any doubt, please confirm with your nearest agricultural officer.",
                    "මෙම නිර්දේශ AI මගින් සහාය දක්වයි. ඒවා 100%ක් නිවැරදි නොවේ. ඔබට කිසියම් සැකයක් ඇත්නම්, කරුණාකර ඔබේ ආසන්නතම ගොවිජන නිලධාරියා සමඟ තහවුරු කරගන්න.",
                    "இந்த பரிந்துரைகள் AI உதவியால் தரப்பட்டவை, 100% துல்லியமானவை அல்ல. சந்தேகம் இருந்தால், உங்கள் அருகிலுள்ள விவசாய அதிகாரியுடன் உறுதிப்படுத்தவும்.",
                  ),
                  style: TextStyle(fontSize: 12, height: 1.4, color: inkOf(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, SmoothRoute(page: const OfficesScreen())),
                  icon: const Icon(Icons.support_agent_rounded, size: 16),
                  label: Text(
                    tr("Agri officer near you", "ආසන්න ගොවිජන නිලධාරියා", "அருகிலுள்ள விவசாய அதிகாரி"),
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => callPhone(kAgriLinkSupportPhone),
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: Text(
                    tr("Call AgriLink support", "AgriLink අමතන්න", "AgriLink-ஐ அழைக்கவும்"),
                    style: const TextStyle(fontSize: 11.5),
                  ),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
