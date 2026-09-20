import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/help_widgets.dart';
import '../widgets/ui_kit.dart';

/// Ask an agriculture officer of your district. Answers arrive in your bell and here.
class AskOfficerScreen extends StatefulWidget {
  const AskOfficerScreen({super.key});

  @override
  State<AskOfficerScreen> createState() => _AskOfficerScreenState();
}

class _AskOfficerScreenState extends State<AskOfficerScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await HelpApi.myQuestions();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r["success"] == true) {
        _items = (r["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _error = null;
      } else {
        _error = apiMessage(r);
      }
    });
  }

  Future<void> _ask() async {
    final text = TextEditingController();
    String crop = "General";
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr("Ask an officer", "නිලධාරියෙකුගෙන් අසන්න", "அலுவலரிடம் கேளுங்கள்"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: crop,
              decoration: InputDecoration(labelText: tr("Crop", "බෝගය", "பயிர்"), border: const OutlineInputBorder()),
              items: ["General", ...allCropNames()].map((c) => DropdownMenuItem(value: c, child: Text(c == "General" ? tr("General", "පොදු", "பொது") : cropLabel(c)))).toList(),
              onChanged: (v) => setS(() => crop = v ?? "General"),
            ),
            const SizedBox(height: 10),
            TextField(controller: text, maxLines: 4, maxLength: 500, decoration: InputDecoration(labelText: tr("What is the problem?", "ගැටලුව කුමක්ද?", "பிரச்சினை என்ன?"), border: const OutlineInputBorder())),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr("Send", "යවන්න", "அனுப்பு")))),
          ]),
        ),
      ),
    );
    if (go != true) return;
    final r = await HelpApi.askQuestion(crop, text.text.trim());
    if (!mounted) return;
    if (r["success"] == true) {
      final n = (r["data"]["officersInDistrict"] as num).toInt();
      showSnack(context, n > 0 ? tr("Sent to the officer of your district.", "ඔබේ දිස්ත්‍රික්කයේ නිලධාරියාට යැවුවා.", "உங்கள் மாவட்ட அலுவலருக்கு அனுப்பப்பட்டது.") : tr("Sent. No officer is registered in your district yet - please also visit your Agrarian Service Centre.", "යැවුවා. ඔබේ දිස්ත්‍රික්කයේ නිලධාරියෙක් තවම ලියාපදිංචි නැත - කරුණාකර ගොවිජන සේවා මධ්‍යස්ථානයටත් යන්න.", "அனுப்பப்பட்டது. உங்கள் மாவட்டத்தில் இன்னும் அலுவலர் இல்லை - விவசாய சேவை மையத்தையும் அணுகவும்."));
      _load();
    } else {
      showSnack(context, apiMessage(r));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("Ask an officer", "නිලධාරියෙකුගෙන් අසන්න", "அலுவலரிடம் கேளுங்கள்"))),
      floatingActionButton: FloatingActionButton.extended(onPressed: _ask, icon: const Icon(Icons.edit_rounded), label: Text(tr("New question", "නව ප්‍රශ්නය", "புதிய கேள்வி"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
          InfoBanner(icon: Icons.support_agent_rounded, text: tr("Officers give general guidance. For chemicals and doses, follow the advice of your Agrarian Service Centre.", "නිලධාරීන් පොදු මග පෙන්වීමක් දෙයි. රසායන හා මාත්‍රා සඳහා ගොවිජන සේවා මධ්‍යස්ථානයේ උපදෙස් අනුගමනය කරන්න.", "அலுவலர்கள் பொது வழிகாட்டல் தருவார்கள். இரசாயனம், அளவுகளுக்கு விவசாய சேவை மையத்தின் ஆலோசனையைப் பின்பற்றவும்.")),
          const SizedBox(height: 12),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
          if (!_loading && _error == null && _items.isEmpty) emptyState(Icons.question_answer_outlined, tr("No questions yet", "ප්‍රශ්න නැත", "கேள்விகள் இல்லை"), tr("Tap “New question” to ask.", "“නව ප්‍රශ්නය” ඔබන්න.", "“புதிய கேள்வி” அழுத்தவும்.")),
          ..._items.map((q) => SoftCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(q["cropType"] == "General" ? tr("General", "පොදු", "பொது") : cropLabel("${q["cropType"]}"), style: const TextStyle(fontWeight: FontWeight.w800))),
                    StatusPill(label: q["status"] == "answered" ? tr("Answered", "පිළිතුරු ලැබුණා", "பதில் வந்தது") : tr("Waiting", "බලාපොරොත්තුවෙන්", "காத்திருக்கிறது"), color: q["status"] == "answered" ? AppColors.forest : AppColors.danger),
                  ]),
                  const SizedBox(height: 4),
                  Text("${q["text"]}", style: const TextStyle(fontSize: 13)),
                  if (q["status"] == "answered") ...[
                    const Divider(height: 18),
                    Row(children: [Expanded(child: Text("${q["answeredBy"]}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))), SpeakButton(text: "${q["answer"]}")]),
                    Text("${q["answer"]}", style: const TextStyle(fontSize: 14)),
                  ],
                ]),
              )),
        ]),
      ),
    );
  }
}
