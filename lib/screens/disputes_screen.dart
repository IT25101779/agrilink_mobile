import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/ui_kit.dart';

/// "My problems": problems raised on my orders. Both sides can write; the AgriLink team can step in.
class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key});

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  final Map<String, TextEditingController> _reply = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await HelpApi.myDisputes();
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

  String _reason(String r) {
    switch (r) {
      case "quality":
        return tr("Bad quality", "අඩු ගුණත්වය", "தரம் குறைவு");
      case "quantity":
        return tr("Wrong amount", "වැරදි ප්‍රමාණය", "தவறான அளவு");
      case "not_delivered":
        return tr("Not delivered", "බෙදා හැරියේ නැත", "வழங்கப்படவில்லை");
      case "not_paid":
        return tr("Not paid", "ගෙවා නැත", "பணம் வரவில்லை");
      case "wrong_price":
        return tr("Wrong price", "වැරදි මිල", "தவறான விலை");
      default:
        return tr("Other", "වෙනත්", "பிற");
    }
  }

  Future<void> _send(Map<String, dynamic> d) async {
    final c = _reply[d["id"]];
    if (c == null || c.text.trim().isEmpty) return;
    final r = await HelpApi.disputeMessage(d["id"], c.text.trim());
    if (!mounted) return;
    if (r["success"] == true) {
      c.clear();
      _load();
    } else {
      showSnack(context, apiMessage(r));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("My problems", "මගේ ගැටලු", "எனது பிரச்சினைகள்"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
          InfoBanner(icon: Icons.handshake_rounded, text: tr("Try to agree with the other person here. If you cannot, the AgriLink team will help.", "මෙහි අනෙක් පුද්ගලයා සමඟ එකඟ වීමට උත්සාහ කරන්න. නොහැකි නම් AgriLink කණ්ඩායම උදව් කරයි.", "இங்கே மற்றவருடன் உடன்பட முயலுங்கள். முடியாவிட்டால் AgriLink குழு உதவும்.")),
          const SizedBox(height: 12),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
          if (!_loading && _error == null && _items.isEmpty) emptyState(Icons.thumb_up_alt_outlined, tr("No problems", "ගැටලු නැත", "பிரச்சினைகள் இல்லை"), tr("Nothing is open. Good!", "විවෘත කිසිවක් නැත. හොඳයි!", "எதுவும் திறந்திருக்கவில்லை. நல்லது!")),
          ..._items.map((d) {
            _reply.putIfAbsent(d["id"], () => TextEditingController());
            final open = d["status"] == "open";
            return SoftCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(_reason("${d["reason"]}"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                  StatusPill(label: open ? tr("Open", "විවෘත", "திறந்தது") : tr("Closed", "වසා ඇත", "மூடப்பட்டது"), color: open ? AppColors.danger : AppColors.forest),
                ]),
                const SizedBox(height: 6),
                ...(d["messages"] as List).map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text("${m["mine"] == true ? tr("You", "ඔබ", "நீங்கள்") : "${m["role"]}"}: ${m["text"]}", style: TextStyle(fontSize: 13, fontWeight: m["mine"] == true ? FontWeight.w700 : FontWeight.w400)),
                    )),
                if ("${d["resolution"]}".isNotEmpty) Container(margin: const EdgeInsets.only(top: 6), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.forestLight, borderRadius: BorderRadius.circular(8)), child: Text("${tr("Decision", "තීරණය", "முடிவு")}: ${d["resolution"]}", style: const TextStyle(fontSize: 13))),
                if (open) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(children: [
                    Expanded(child: TextField(controller: _reply[d["id"]], maxLength: 400, decoration: InputDecoration(counterText: "", hintText: tr("Write a message", "පණිවිඩයක් ලියන්න", "செய்தி எழுதுங்கள்"), border: const OutlineInputBorder(), isDense: true))),
                    IconButton(icon: const Icon(Icons.send_rounded, color: AppColors.forest), onPressed: () => _send(d)),
                  ]),
                ),
              ]),
            );
          }),
        ]),
      ),
    );
  }
}
