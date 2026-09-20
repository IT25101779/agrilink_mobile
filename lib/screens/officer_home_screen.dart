import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/auth_service.dart';
import '../services/help_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/language_toggle.dart';
import '../widgets/ui_kit.dart';
import 'login_screen.dart';

/// Home for agriculture officers (accounts made by the AgriLink admin): questions from farmers of their
/// districts, and disease reports coming in from those districts.
class OfficerHomeScreen extends StatefulWidget {
  const OfficerHomeScreen({super.key});

  @override
  State<OfficerHomeScreen> createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await HelpApi.officerOverview();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r["success"] == true) {
        _data = Map<String, dynamic>.from(r["data"] as Map);
        _error = null;
      } else {
        _error = apiMessage(r);
      }
    });
  }

  Future<void> _answer(Map<String, dynamic> q) async {
    final c = TextEditingController();
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("${q["farmerName"]} • ${q["cropType"]}", style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text("${q["text"]}"),
          const SizedBox(height: 10),
          TextField(controller: c, maxLines: 5, maxLength: 800, decoration: InputDecoration(labelText: tr("Your answer", "ඔබේ පිළිතුර", "உங்கள் பதில்"), border: const OutlineInputBorder())),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr("Send answer", "පිළිතුර යවන්න", "பதிலை அனுப்பு")))),
        ]),
      ),
    );
    if (go != true) return;
    final r = await HelpApi.answerQuestion(q["id"], c.text.trim());
    if (!mounted) return;
    showSnack(context, r["success"] == true ? tr("Answer sent.", "පිළිතුර යැවුවා.", "பதில் அனுப்பப்பட்டது.") : apiMessage(r));
    if (r["success"] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final questions = (_data?["questions"] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final outbreaks = (_data?["outbreaks"] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("Officer desk", "නිලධාරී මේසය", "அலுவலர் மேசை")),
        actions: [
          const LanguageToggle(),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await AuthService.logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
          if (_data != null) Text("${tr("Your districts", "ඔබේ දිස්ත්‍රික්ක", "உங்கள் மாவட்டங்கள்")}: ${(_data!["districts"] as List).join(", ")}", style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
          const SizedBox(height: 8),
          SectionHeader(title: tr("Disease reports (last 14 days)", "රෝග වාර්තා (දින 14)", "நோய் அறிக்கைகள் (14 நாட்கள்)")),
          if (!_loading && outbreaks.isEmpty) Text(tr("No disease reports in your districts.", "ඔබේ දිස්ත්‍රික්කවල රෝග වාර්තා නැත.", "உங்கள் மாவட்டங்களில் நோய் அறிக்கைகள் இல்லை."), style: const TextStyle(color: AppColors.inkMuted)),
          ...outbreaks.map((o) => SoftCard(child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("${o["disease"]}", style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text("${o["cropType"]} • ${o["district"]}", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                ])),
                StatusPill(label: "${o["reports"]} ${tr("reports", "වාර්තා", "அறிக்கைகள்")}", color: (o["reports"] as num) >= 5 ? AppColors.danger : AppColors.forest),
              ]))),
          const SizedBox(height: 8),
          SectionHeader(title: tr("Questions from farmers", "ගොවීන්ගේ ප්‍රශ්න", "விவசாயிகளின் கேள்விகள்")),
          if (!_loading && questions.isEmpty) Text(tr("No open questions.", "විවෘත ප්‍රශ්න නැත.", "திறந்த கேள்விகள் இல்லை."), style: const TextStyle(color: AppColors.inkMuted)),
          ...questions.map((q) => SoftCard(
                onTap: () => _answer(q),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("${q["farmerName"]} • ${q["cropType"]} • ${q["district"]}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text("${q["text"]}"),
                ]),
              )),
        ]),
      ),
    );
  }
}
