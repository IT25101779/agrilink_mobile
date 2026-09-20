import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../models/pest_data.dart';
import '../theme/app_theme.dart';
import '../widgets/help_widgets.dart';
import '../widgets/ui_kit.dart';

/// Works with no internet. General guidance only - never doses or chemical names.
class PestLibraryScreen extends StatefulWidget {
  const PestLibraryScreen({super.key});

  @override
  State<PestLibraryScreen> createState() => _PestLibraryScreenState();
}

class _PestLibraryScreenState extends State<PestLibraryScreen> {
  String _q = "";

  int get _lang => isSinhala() ? 1 : isTamil() ? 2 : 0;

  @override
  Widget build(BuildContext context) {
    final items = kPestLibrary.where((p) {
      final q = _q.trim().toLowerCase();
      return q.isEmpty || p.name.any((n) => n.toLowerCase().contains(q)) || p.crops.any((c) => c.toLowerCase().contains(q));
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text(tr("Pest & disease guide", "පළිබෝධ හා රෝග මාර්ගෝපදේශය", "பூச்சி & நோய் வழிகாட்டி"))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
        InfoBanner(icon: Icons.offline_pin_rounded, text: tr("Works without internet. For sprays and doses, always follow your Agrarian Service Centre.", "අන්තර්ජාලයෙන් තොරව ක්‍රියා කරයි. ඉසින හා මාත්‍රා සඳහා සෑම විටම ගොවිජන සේවා මධ්‍යස්ථානයේ උපදෙස් අනුගමනය කරන්න.", "இணையம் இல்லாமல் செயல்படும். தெளிப்பு, அளவுகளுக்கு எப்போதும் விவசாய சேவை மையத்தைப் பின்பற்றவும்.")),
        const SizedBox(height: 10),
        TextField(onChanged: (v) => setState(() => _q = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: tr("Search crop or problem", "බෝගය හෝ ගැටලුව සොයන්න", "பயிர் அல்லது பிரச்சினை தேடு"), border: const OutlineInputBorder())),
        const SizedBox(height: 12),
        ...items.map((p) => SoftCard(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _PestDetail(entry: p))),
              child: Row(children: [
                Text(p.emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name[_lang], style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(p.crops.join(", "), style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                ])),
                const Icon(Icons.chevron_right_rounded),
              ]),
            )),
      ]),
    );
  }
}

class _PestDetail extends StatelessWidget {
  final PestEntry entry;
  const _PestDetail({required this.entry});

  @override
  Widget build(BuildContext context) {
    final l = isSinhala() ? 1 : isTamil() ? 2 : 0;
    return Scaffold(
      appBar: AppBar(title: Text(entry.name[l], style: const TextStyle(fontSize: 16))),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [Text(entry.emoji, style: const TextStyle(fontSize: 40)), const Spacer(), SpeakButton(text: "${entry.name[l]}. ${entry.signs[l]} ${entry.action[l]}")]),
        const SizedBox(height: 8),
        Text(tr("What you see", "ඔබ දකින දේ", "நீங்கள் காண்பது"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 4),
        Text(entry.signs[l], style: const TextStyle(fontSize: 15, height: 1.4)),
        const SizedBox(height: 16),
        Text(tr("What to do", "කළ යුතු දේ", "செய்ய வேண்டியது"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 4),
        Text(entry.action[l], style: const TextStyle(fontSize: 15, height: 1.4)),
        const SizedBox(height: 16),
        InfoBanner(icon: Icons.camera_alt_rounded, text: tr("Not sure? Use the Disease Scanner tab to photograph the leaf, or ask an officer.", "විශ්වාස නැද්ද? රෝග පරීක්ෂකය මගින් කොළය ඡායාරූප ගන්න, නැතහොත් නිලධාරියෙකුගෙන් අසන්න.", "உறுதியில்லையா? நோய் ஸ்கேனரில் இலையைப் படமெடுங்கள் அல்லது அலுவலரிடம் கேளுங்கள்.")),
      ]),
    );
  }
}
