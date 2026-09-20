import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/farm_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/ui_kit.dart';

/// Short surveys from the AgriLink team. Real answers from real farmers shape what gets built next.
class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  List<Map<String, dynamic>> _surveys = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await FarmApi.openSurveys();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result["success"] == true) {
        _surveys = (result["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _error = apiMessage(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("Quick surveys", "කෙටි සමීක්ෂණ", "விரைவு கருத்துக்கணிப்புகள்"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
          Text(tr("Your answers help us build tools for farmers like you.", "ඔබේ පිළිතුරු ඔබ වැනි ගොවීන් සඳහා මෙවලම් සෑදීමට උපකාරී වේ.", "உங்கள் பதில்கள் உங்களைப் போன்ற விவசாயிகளுக்கான கருவிகளை உருவாக்க உதவுகின்றன."), style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
          const SizedBox(height: 12),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
          if (!_loading && _error == null && _surveys.isEmpty) emptyState(Icons.poll_outlined, tr("No open surveys", "විවෘත සමීක්ෂණ නැත", "திறந்த கருத்துக்கணிப்புகள் இல்லை"), tr("Thank you! New surveys will appear here.", "ස්තූතියි! නව සමීක්ෂණ මෙහි දිස්වේ.", "நன்றி! புதிய கருத்துக்கணிப்புகள் இங்கே தோன்றும்.")),
          ..._surveys.map((s) => SoftCard(
                onTap: () async {
                  final done = await Navigator.push(context, MaterialPageRoute(builder: (_) => _SurveyForm(survey: s)));
                  if (done == true) _load();
                },
                child: Row(children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFB45309).withOpacity(0.12), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.poll_rounded, color: Color(0xFFB45309))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("${s["title"]}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text("${(s["questions"] as List).length} ${tr("questions · about 2 min", "ප්‍රශ්න · විනාඩි 2ක් පමණ", "கேள்விகள் · சுமார் 2 நிமிடம்")}", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  ])),
                  const Icon(Icons.chevron_right_rounded),
                ]),
              )),
        ]),
      ),
    );
  }
}

class _SurveyForm extends StatefulWidget {
  final Map<String, dynamic> survey;
  const _SurveyForm({required this.survey});

  @override
  State<_SurveyForm> createState() => _SurveyFormState();
}

class _SurveyFormState extends State<_SurveyForm> {
  final Map<String, dynamic> _answers = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _sending = false;
  String? _error;

  List<Map<String, dynamic>> get _questions => (widget.survey["questions"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  TextEditingController _controller(String key) => _controllers.putIfAbsent(key, () => TextEditingController());

  Future<void> _submit() async {
    final answers = <String, dynamic>{};
    for (final q in _questions) {
      final key = "${q["key"]}";
      if (q["kind"] == "number" || q["kind"] == "text") {
        final text = _controller(key).text.trim();
        if (text.isNotEmpty) answers[key] = q["kind"] == "number" ? (double.tryParse(text) ?? text) : text;
      } else if (_answers[key] != null) {
        answers[key] = _answers[key];
      }
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    final result = await FarmApi.respondSurvey("${widget.survey["id"]}", answers);
    if (!mounted) return;
    setState(() => _sending = false);
    if (result["success"] == true) {
      showSnack(context, tr("Thank you! Your answer helps every farmer.", "ස්තූතියි! ඔබේ පිළිතුර සෑම ගොවියෙකුටම උපකාරී වේ.", "நன்றி! உங்கள் பதில் ஒவ்வொரு விவசாயிக்கும் உதவும்."));
      Navigator.pop(context, true);
    } else {
      setState(() => _error = apiMessage(result));
    }
  }

  Widget _input(Map<String, dynamic> q) {
    final key = "${q["key"]}";
    switch (q["kind"]) {
      case "single":
        return Wrap(spacing: 8, runSpacing: 4, children: (q["options"] as List).map((o) => ChoiceChip(label: Text("$o", style: const TextStyle(fontSize: 12.5)), selected: _answers[key] == o, onSelected: (_) => setState(() => _answers[key] = o))).toList());
      case "scale":
        return Row(children: [1, 2, 3, 4, 5].map((n) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text("$n"), selected: _answers[key] == n, onSelected: (_) => setState(() => _answers[key] = n)))).toList());
      case "number":
        return TextField(controller: _controller(key), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(suffixText: "${q["unit"] ?? ""}"));
      default:
        return TextField(controller: _controller(key), maxLines: 3, maxLength: 300, decoration: InputDecoration(hintText: tr("Write here (no phone numbers)", "මෙහි ලියන්න (දුරකථන අංක නැතිව)", "இங்கே எழுதுங்கள் (தொலைபேசி எண் வேண்டாம்)")));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.survey["title"]}")),
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 40), children: [
        if ("${widget.survey["intro"] ?? ""}".isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text("${widget.survey["intro"]}", style: const TextStyle(color: AppColors.inkMuted))),
        ..._questions.asMap().entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("${entry.key + 1}. ${entry.value["text"]}${entry.value["required"] == true ? " *" : ""}", style: const TextStyle(fontWeight: FontWeight.w700, height: 1.35)),
                const SizedBox(height: 8),
                _input(entry.value),
              ]),
            )),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _sending ? null : _submit, child: _sending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(tr("Submit", "යවන්න", "சமர்ப்பி")))),
      ]),
    );
  }
}
