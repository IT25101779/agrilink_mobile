import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/auth_service.dart';
import '../services/help_api.dart';
import '../services/profile_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/help_widgets.dart';
import '../widgets/ui_kit.dart';

/// Send a photo of your NIC (or business registration) to get a Verified badge that buyers can trust.
class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  String _status = "none", _note = "", _role = "farmer", _doc = "nic";
  bool _loading = true, _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _role = await AuthService.getUserRole() ?? "farmer";
    _doc = _role == "buyer" ? "business_reg" : "nic";
    final r = await ProfileApi.me();
    if (!mounted) return;
    setState(() {
      _loading = false;
      final v = (r["data"] is Map ? (r["data"] as Map)["verification"] : null) as Map?;
      _status = "${v?["status"] ?? "none"}";
      _note = "${v?["note"] ?? ""}";
    });
  }

  Future<void> _send() async {
    final p = await askAndPickPhoto(context);
    if (p == null || !mounted) return;
    if (p == "TOO_BIG") return showSnack(context, tr("That photo is too large.", "ඡායාරූපය විශාල වැඩියි.", "படம் மிகப் பெரியது."));
    setState(() => _sending = true);
    final r = await HelpApi.submitVerification(_doc, p);
    if (!mounted) return;
    setState(() => _sending = false);
    showSnack(context, apiMessage(r));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final verified = _status == "verified", pending = _status == "pending";
    return Scaffold(
      appBar: AppBar(title: Text(tr("Get verified", "සත්‍යාපනය", "சரிபார்ப்பு"))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              InfoBanner(icon: verified ? Icons.verified_rounded : Icons.shield_rounded, color: verified ? AppColors.forest : AppColors.inkMuted, text: verified ? tr("You are verified. Buyers see a ✓ badge on your listings.", "ඔබ සත්‍යාපිතයි. ගැනුම්කරුවන්ට ඔබේ ලැයිස්තුවල ✓ ලාංඡනය පෙනේ.", "நீங்கள் சரிபார்க்கப்பட்டீர்கள். வாங்குபவர்கள் ✓ முத்திரையைப் பார்ப்பார்கள்.") : pending ? tr("Your document is being checked.", "ඔබේ ලේඛනය පරීක්ෂා කරමින් පවතී.", "உங்கள் ஆவணம் சரிபார்க்கப்படுகிறது.") : tr("A ✓ badge helps buyers trust you.", "✓ ලාංඡනයක් ගැනුම්කරුවන්ගේ විශ්වාසය ඉහළ නංවයි.", "✓ முத்திரை வாங்குபவர் நம்பிக்கையை உயர்த்தும்.")),
              if (_status == "rejected") Padding(padding: const EdgeInsets.only(top: 10), child: InfoBanner(icon: Icons.error_outline_rounded, color: AppColors.danger, text: "${tr("Not accepted", "පිළිගත්තේ නැත", "ஏற்கப்படவில்லை")}: $_note")),
              const SizedBox(height: 14),
              Text(tr("Privacy: only the AgriLink team sees your photo, and it is deleted as soon as they decide.", "රහස්‍යතාව: ඔබේ ඡායාරූපය දකින්නේ AgriLink කණ්ඩායම පමණි; තීරණය කළ වහාම මකා දමයි.", "தனியுரிமை: உங்கள் படத்தை AgriLink குழு மட்டுமே பார்க்கும்; முடிவெடுத்ததும் நீக்கப்படும்."), style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
              const SizedBox(height: 14),
              if (_role == "farmer") Wrap(spacing: 8, children: [
                ChoiceChip(label: Text(tr("NIC", "ජා.හැ.අ.", "தே.அ.அ.")), selected: _doc == "nic", onSelected: (_) => setState(() => _doc = "nic")),
                ChoiceChip(label: Text(tr("Farmer card", "ගොවි කාඩ්පත", "விவசாய அட்டை")), selected: _doc == "farmer_card", onSelected: (_) => setState(() => _doc = "farmer_card")),
              ]),
              const SizedBox(height: 14),
              if (!verified && !pending) SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _sending ? null : _send, icon: const Icon(Icons.add_a_photo_rounded), label: Text(_sending ? tr("Sending...", "යවමින්...", "அனுப்புகிறது...") : tr("Take photo of document", "ලේඛනයේ ඡායාරූපය ගන්න", "ஆவணத்தைப் படமெடு")))),
            ]),
    );
  }
}
