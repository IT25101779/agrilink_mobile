import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/help_widgets.dart';
import '../widgets/ui_kit.dart';

/// "How I get paid": a short note and your bank-app QR photo. Buyers see it only after you dispatch an order.
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _text = TextEditingController();
  bool _hasQr = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await HelpApi.getPayment();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r["success"] == true) {
        _text.text = "${r["data"]["instructions"]}";
        _hasQr = r["data"]["hasQr"] == true;
      }
    });
  }

  Future<void> _save() async {
    final r = await HelpApi.setPayment(_text.text.trim());
    if (mounted) showSnack(context, r["success"] == true ? tr("Saved.", "සුරකින ලදි.", "சேமிக்கப்பட்டது.") : apiMessage(r));
  }

  Future<void> _uploadQr() async {
    final p = await askAndPickPhoto(context);
    if (p == null || !mounted) return;
    if (p == "TOO_BIG") return showSnack(context, tr("That photo is too large.", "ඡායාරූපය විශාල වැඩියි.", "படம் மிகப் பெரியது."));
    final r = await HelpApi.setPaymentQr(p);
    if (!mounted) return;
    showSnack(context, r["success"] == true ? tr("QR saved.", "QR සුරකින ලදි.", "QR சேமிக்கப்பட்டது.") : apiMessage(r));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("How I get paid", "මට ගෙවන ආකාරය", "எனக்கு பணம் செலுத்தும் முறை"))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              InfoBanner(icon: Icons.lock_rounded, text: tr("Buyers see this only after you dispatch their order. Don't write card numbers or PINs. A bank-app QR is safest.", "ඔබ ඇණවුම යැවූ පසු පමණක් ගැනුම්කරුට පෙනේ. කාඩ්පත් අංක හෝ PIN ලියන්න එපා. බැංකු යෙදුමේ QR වඩාත් ආරක්ෂිතයි.", "நீங்கள் ஆர்டரை அனுப்பிய பின்பே வாங்குபவருக்குத் தெரியும். அட்டை எண், PIN எழுதாதீர்கள். வங்கி செயலி QR பாதுகாப்பானது.")),
              const SizedBox(height: 14),
              TextField(controller: _text, maxLength: 200, maxLines: 3, decoration: InputDecoration(labelText: tr("Payment note (e.g. bank transfer to ...)", "ගෙවීම් සටහන (උදා: බැංකු ගිණුමට ...)", "கட்டணக் குறிப்பு (எ.கா. வங்கிக் கணக்கு ...)"), border: const OutlineInputBorder())),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: Text(tr("Save note", "සටහන සුරකින්න", "குறிப்பைச் சேமி")))),
              const Divider(height: 32),
              Text(_hasQr ? tr("A QR photo is saved.", "QR ඡායාරූපයක් සුරකින ලදි.", "QR படம் சேமிக்கப்பட்டது.") : tr("No QR photo yet.", "තවම QR ඡායාරූපයක් නැත.", "இன்னும் QR படம் இல்லை."), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _uploadQr, icon: const Icon(Icons.qr_code_2_rounded), label: Text(tr("Add / change QR", "QR එක් කරන්න / වෙනස් කරන්න", "QR சேர் / மாற்று")))),
                if (_hasQr) IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), onPressed: () async {
                  await HelpApi.removePaymentQr();
                  _load();
                }),
              ]),
            ]),
    );
  }
}
