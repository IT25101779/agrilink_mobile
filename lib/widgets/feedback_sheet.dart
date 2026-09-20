import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import 'farm_common.dart';

/// "Tell us what's wrong or what you'd like" - reaches the AgriLink team. Works offline (sent later).
Future<void> showFeedbackSheet(BuildContext context, {String screen = ""}) async {
  String kind = "idea";
  final text = TextEditingController();
  final send = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr("Tell us", "අපට කියන්න", "எங்களிடம் சொல்லுங்கள்"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: Text(tr("Something is broken", "යමක් අක්‍රියයි", "ஏதோ பழுது")), selected: kind == "bug", onSelected: (_) => setS(() => kind = "bug")),
            ChoiceChip(label: Text(tr("I have an idea", "මට අදහසක් ඇත", "என்னிடம் ஒரு யோசனை")), selected: kind == "idea", onSelected: (_) => setS(() => kind = "idea")),
            ChoiceChip(label: Text(tr("I need help", "මට උදව් අවශ්‍යයි", "எனக்கு உதவி வேண்டும்")), selected: kind == "help", onSelected: (_) => setS(() => kind = "help")),
            ChoiceChip(label: Text(tr("I like it", "මම කැමතියි", "பிடித்திருக்கிறது")), selected: kind == "praise", onSelected: (_) => setS(() => kind = "praise")),
          ]),
          const SizedBox(height: 8),
          TextField(controller: text, maxLines: 4, maxLength: 600, decoration: InputDecoration(border: const OutlineInputBorder(), hintText: tr("Write here (Sinhala, Tamil or English)", "මෙහි ලියන්න (සිංහල, දෙමළ හෝ ඉංග්‍රීසි)", "இங்கே எழுதுங்கள் (சிங்களம், தமிழ், ஆங்கிலம்)"))),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr("Send", "යවන්න", "அனுப்பு")))),
        ]),
      ),
    ),
  );
  if (send != true || text.text.trim().isEmpty) return;
  final r = await HelpApi.feedback(kind, text.text.trim(), screen);
  if (context.mounted) showSnack(context, r["success"] == true ? (r["queued"] == true ? apiMessage(r) : tr("Thank you! We read every message.", "ස්තූතියි! සෑම පණිවිඩයක්ම අපි කියවමු.", "நன்றி! ஒவ்வொரு செய்தியையும் படிக்கிறோம்.")) : apiMessage(r));
}
