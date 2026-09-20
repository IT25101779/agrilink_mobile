import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/tr.dart';
import '../screens/login_screen.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/help_api.dart';
import '../services/share_helper.dart';

/// Shown once per privacy-notice version: the person reads (or opens) the notice and agrees, or leaves.
class ConsentGate {
  static const _key = "consent_2026-09";

  static Future<void> check(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key) == true || !context.mounted) return;
    final agree = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(tr("Your privacy", "ඔබේ රහස්‍යතාව", "உங்கள் தனியுரிமை")),
        content: SingleChildScrollView(
          child: Text(tr("AgriLink keeps your name, phone, district, farm records and the photos you choose to upload, to run the marketplace and alerts. We do not sell your data. You can download or delete everything anytime in Profile → Settings.", "AgriLink ඔබේ නම, දුරකථනය, දිස්ත්‍රික්කය, ගොවිපල වාර්තා හා ඔබ උඩුගත කරන ඡායාරූප වෙළඳපොළ හා දැනුම්දීම් සඳහා තබා ගනී. ඔබේ දත්ත අපි විකුණන්නේ නැත. ඕනෑම වේලාවක පැතිකඩ → සැකසුම් හි ඒවා බාගත හෝ මකා දැමිය හැක.", "AgriLink உங்கள் பெயர், தொலைபேசி, மாவட்டம், பண்ணைப் பதிவுகள், நீங்கள் பதிவேற்றும் படங்களை சந்தை, எச்சரிக்கைகளுக்காக வைத்திருக்கும். தரவை விற்கமாட்டோம். சுயவிவரம் → அமைப்புகளில் எப்போது வேண்டுமானாலும் பதிவிறக்கலாம்/நீக்கலாம்.")),
        ),
        actions: [
          TextButton(onPressed: () => ShareHelper.openLink(HelpApi.privacyUrl), child: Text(tr("Read full notice", "සම්පූර්ණ දැන්වීම කියවන්න", "முழு அறிவிப்பைப் படி"))),
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr("No, log me out", "නැත, ඉවත් කරන්න", "வேண்டாம், வெளியேற்று"))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr("I agree", "එකඟයි", "ஒப்புக்கொள்கிறேன்"))),
        ],
      ),
    );
    if (agree == true) {
      await prefs.setBool(_key, true);
      HelpApi.consent();
    } else if (agree == false && context.mounted) {
      await AuthService.logout();
      if (context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    }
  }
}

/// Asks an old app to update when the server says this version is too old.
class VersionGate {
  static List<int> _parts(String v) => v.split(".").map((p) => int.tryParse(p) ?? 0).toList();

  static bool _older(String a, String b) {
    final x = _parts(a), y = _parts(b);
    for (int i = 0; i < 3; i++) {
      final p = i < x.length ? x[i] : 0, q = i < y.length ? y[i] : 0;
      if (p != q) return p < q;
    }
    return false;
  }

  static Future<void> check(BuildContext context) async {
    final r = await HelpApi.appVersion();
    if (r["success"] != true || !context.mounted) return;
    final d = Map<String, dynamic>.from(r["data"] as Map);
    final tooOld = _older(AppSettings.appVersion, "${d["minVersion"]}");
    final canUpdate = _older(AppSettings.appVersion, "${d["latestVersion"]}");
    if (!tooOld && !canUpdate) return;
    final url = "${d["downloadUrl"]}";
    await showDialog(
      context: context,
      barrierDismissible: !tooOld,
      builder: (ctx) => PopScope(
        canPop: !tooOld,
        child: AlertDialog(
          title: Text(tooOld ? tr("Please update the app", "කරුණාකර යෙදුම යාවත්කාලීන කරන්න", "செயலியைப் புதுப்பிக்கவும்") : tr("A new version is ready", "නව සංස්කරණයක් ඇත", "புதிய பதிப்பு உள்ளது")),
          content: Text("${d["message"]}".isNotEmpty ? "${d["message"]}" : tooOld ? tr("This version is too old to work properly.", "මෙම සංස්කරණය නිසි ලෙස ක්‍රියා කිරීමට ඉතා පැරණියි.", "இந்த பதிப்பு சரியாக இயங்க மிகப் பழையது.") : tr("Update for the latest features and fixes.", "නවතම පහසුකම් සඳහා යාවත්කාලීන කරන්න.", "புதிய வசதிகளுக்குப் புதுப்பிக்கவும்.")),
          actions: [
            if (!tooOld) TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr("Later", "පසුව", "பின்னர்"))),
            if (url.isNotEmpty) ElevatedButton(onPressed: () => ShareHelper.openLink(url), child: Text(tr("Update", "යාවත්කාලීන", "புதுப்பி"))),
          ],
        ),
      ),
    );
  }
}
