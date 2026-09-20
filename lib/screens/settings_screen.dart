import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../localization/tr.dart';
import '../services/app_settings.dart';
import '../services/auth_service.dart';
import '../services/help_api.dart';
import '../services/offline_store.dart';
import '../services/profile_api.dart';
import '../services/share_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/feedback_sheet.dart';
import '../widgets/ui_kit.dart';
import 'login_screen.dart';
import 'payment_screen.dart';
import 'verification_screen.dart';

/// Phone settings, data saving, alerts, privacy and account controls.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _sms = false, _loading = true;
  String _role = "farmer", _code = "", _verification = "none";
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _role = await AuthService.getUserRole() ?? "farmer";
    final me = await ProfileApi.me();
    final ref = await HelpApi.referrals();
    _pending = await OfflineStore.pendingCount();
    if (!mounted) return;
    setState(() {
      _loading = false;
      final u = me["data"] is Map ? Map<String, dynamic>.from(me["data"] as Map) : <String, dynamic>{};
      _sms = u["smsAlerts"] == true;
      _verification = "${(u["verification"] as Map?)?["status"] ?? "none"}";
      _code = ref["success"] == true ? "${ref["data"]["code"]}" : "";
    });
  }

  Future<void> _export() async {
    final body = await HelpApi.exportData();
    await Clipboard.setData(ClipboardData(text: body));
    if (mounted) showSnack(context, tr("All your data was copied. Paste it into a note or message to keep it.", "ඔබේ සියලු දත්ත පිටපත් කළා. තබා ගැනීමට සටහනකට අලවන්න.", "உங்கள் தரவு நகலெடுக்கப்பட்டது. வைத்திருக்க குறிப்பில் ஒட்டவும்."));
  }

  Future<void> _delete() async {
    final pw = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr("Delete my account", "මගේ ගිණුම මකන්න", "எனது கணக்கை நீக்கு")),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr("This erases your details, records and open listings. It cannot be undone. Finished orders stay for the other person's records, with your name removed.", "මෙය ඔබේ විස්තර, වාර්තා හා විවෘත ලැයිස්තු මකයි. ආපසු හැරවිය නොහැක. අවසන් ඇණවුම් අනෙක් පුද්ගලයාගේ වාර්තා සඳහා ඔබේ නම ඉවත් කර පවතී.", "இது உங்கள் விவரங்கள், பதிவுகள், திறந்த பட்டியல்களை அழிக்கும். மீட்க முடியாது. முடிந்த ஆர்டர்கள் மற்றவரின் பதிவுக்காக உங்கள் பெயர் நீக்கப்பட்டு இருக்கும்."), style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 10),
          TextField(controller: pw, obscureText: true, decoration: InputDecoration(labelText: tr("Your password", "ඔබේ මුරපදය", "உங்கள் கடவுச்சொல்"), border: const OutlineInputBorder())),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr("Cancel", "අවලංගු", "ரத்து"))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger), onPressed: () => Navigator.pop(ctx, true), child: Text(tr("Delete", "මකන්න", "நீக்கு")))],
      ),
    );
    if (go != true) return;
    final r = await HelpApi.deleteAccount(pw.text);
    if (!mounted) return;
    if (r["success"] == true) {
      await AuthService.logout();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
    } else {
      showSnack(context, apiMessage(r));
    }
  }

  Widget _section(String t) => Padding(padding: const EdgeInsets.fromLTRB(4, 18, 4, 6), child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.inkMuted)));

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.instance;
    return Scaffold(
      appBar: AppBar(title: Text(tr("Settings & privacy", "සැකසුම් හා රහස්‍යතාව", "அமைப்புகள் & தனியுரிமை"))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListenableBuilder(
              listenable: s,
              builder: (context, _) => ListView(padding: const EdgeInsets.fromLTRB(12, 4, 12, 40), children: [
                _section(tr("SAVE DATA & MAKE IT SIMPLE", "දත්ත ඉතිරි කරන්න හා සරල කරන්න", "தரவைச் சேமி & எளிமையாக்கு")),
                SwitchListTile(value: s.lowData, onChanged: s.setLowData, title: Text(tr("Low-data mode", "අඩු දත්ත ප්‍රකාරය", "குறைந்த தரவு முறை")), subtitle: Text(tr("No crop photos or picture ads. Saves mobile data.", "බෝග ඡායාරූප හෝ පින්තූර දැන්වීම් නැත. දත්ත ඉතිරි කරයි.", "பயிர் படங்கள், பட விளம்பரங்கள் இல்லை. தரவைச் சேமிக்கும்."))),
                Padding(padding: const EdgeInsets.only(left: 16, bottom: 6), child: Text("${tr("Data used this month", "මෙම මාසයේ භාවිත දත්ත", "இந்த மாதம் பயன்படுத்திய தரவு")}: ${s.usageText}", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted))),
                SwitchListTile(value: s.simpleMode, onChanged: s.setSimpleMode, title: Text(tr("Simple mode", "සරල ප්‍රකාරය", "எளிய முறை")), subtitle: Text(tr("Big buttons with pictures. Press and hold a button to hear it read out.", "පින්තූර සහිත විශාල බොත්තම්. බොත්තමක් ඔබාගෙන සිටියොත් කියවයි.", "படங்களுடன் பெரிய பொத்தான்கள். அழுத்திப் பிடித்தால் வாசிக்கும்."))),
                if (_pending > 0) ListTile(leading: const Icon(Icons.sync_rounded), title: Text("$_pending ${tr("records waiting for internet", "වාර්තා අන්තර්ජාලය බලාපොරොත්තුවෙන්", "பதிவுகள் இணையத்திற்காகக் காத்திருக்கின்றன")}"), trailing: TextButton(onPressed: () async { await OfflineStore.flush(); _load(); }, child: Text(tr("Send now", "දැන් යවන්න", "இப்போது அனுப்பு")))),
                if (_role == "farmer") ...[
                  _section(tr("ALERTS", "දැනුම්දීම්", "எச்சரிக்கைகள்")),
                  SwitchListTile(value: _sms, onChanged: (v) async {
                    setState(() => _sms = v);
                    await ProfileApi.update({"smsAlerts": v});
                  }, title: Text(tr("Important alerts by SMS", "වැදගත් දැනුම්දීම් SMS මගින්", "முக்கிய எச்சரிக்கைகள் SMS மூலம்")), subtitle: Text(tr("Orders, price alerts, disease and wildlife warnings. Limited each month.", "ඇණවුම්, මිල, රෝග හා වන සත්ව අනතුරු. මාසිකව සීමිතයි.", "ஆர்டர், விலை, நோய், வனவிலங்கு எச்சரிக்கைகள். மாதம் வரம்புடன்."))),
                  ListTile(leading: const Icon(Icons.payments_rounded), title: Text(tr("How I get paid", "මට ගෙවන ආකාරය", "எனக்கு பணம் செலுத்தும் முறை")), trailing: const Icon(Icons.chevron_right_rounded), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen()))),
                ],
                _section(tr("TRUST", "විශ්වාසය", "நம்பிக்கை")),
                ListTile(leading: Icon(Icons.verified_rounded, color: _verification == "verified" ? AppColors.forest : null), title: Text(tr("Get verified", "සත්‍යාපනය", "சரிபார்ப்பு")), subtitle: Text(_verification == "verified" ? tr("Verified ✓", "සත්‍යාපිතයි ✓", "சரிபார்க்கப்பட்டது ✓") : _verification == "pending" ? tr("Being checked", "පරීක්ෂා කරමින්", "சரிபார்க்கப்படுகிறது") : ""), trailing: const Icon(Icons.chevron_right_rounded), onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) => const VerificationScreen()));
                  _load();
                }),
                if (_code.isNotEmpty) ListTile(leading: const Icon(Icons.group_add_rounded), title: Text("${tr("Invite a farmer", "ගොවියෙකුට ආරාධනා කරන්න", "விவசாயியை அழை")} • $_code"), subtitle: Text(tr("They enter this code when registering.", "ලියාපදිංචි වන විට මෙම කේතය ඇතුළත් කරයි.", "பதிவு செய்யும்போது இந்த குறியீட்டை உள்ளிடுவார்கள்.")), trailing: IconButton(icon: const Icon(Icons.share_rounded), onPressed: () => ShareHelper.whatsapp("${tr("Join me on AgriLink - prices, buyers and farm tools in one app. Use my code when you register", "AgriLink හි මා සමඟ එක්වන්න - මිල, ගැනුම්කරුවන් හා ගොවි මෙවලම් එක් යෙදුමක. ලියාපදිංචි වීමේදී මගේ කේතය භාවිතා කරන්න", "AgriLink-இல் என்னுடன் சேருங்கள் - விலை, வாங்குபவர், பண்ணைக் கருவிகள் ஒரே செயலியில். பதிவின்போது என் குறியீட்டைப் பயன்படுத்துங்கள்")}: $_code"))),
                ListTile(leading: const Icon(Icons.feedback_rounded), title: Text(tr("Tell us what to improve", "වැඩි දියුණු කළ යුතු දේ කියන්න", "எதை மேம்படுத்த வேண்டும் என்று சொல்லுங்கள்")), onTap: () => showFeedbackSheet(context, screen: "settings")),
                _section(tr("YOUR DATA", "ඔබේ දත්ත", "உங்கள் தரவு")),
                ListTile(leading: const Icon(Icons.policy_rounded), title: Text(tr("Privacy notice", "රහස්‍යතා දැන්වීම", "தனியுரிமை அறிவிப்பு")), onTap: () => ShareHelper.openLink(HelpApi.privacyUrl)),
                ListTile(leading: const Icon(Icons.download_rounded), title: Text(tr("Download all my data", "මගේ සියලු දත්ත බාගන්න", "எனது எல்லா தரவையும் பதிவிறக்கு")), onTap: _export),
                ListTile(leading: const Icon(Icons.delete_forever_rounded, color: AppColors.danger), title: Text(tr("Delete my account", "මගේ ගිණුම මකන්න", "எனது கணக்கை நீக்கு"), style: const TextStyle(color: AppColors.danger)), onTap: _delete),
                Padding(padding: const EdgeInsets.all(16), child: Text("AgriLink ${AppSettings.appVersion}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.inkMuted))),
              ]),
            ),
    );
  }
}
