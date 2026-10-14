import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../localization/tr.dart';
import '../services/auth_service.dart';
import '../services/insights_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/ui_kit.dart';

/// FORWARD / CONTRACT LISTINGS.
///
/// A buyer locks in a price for a future delivery BEFORE the farmer plants —
/// unlike the normal marketplace, which only sells what's already harvested.
/// Same phone-first pattern as everywhere else: express interest -> see the
/// buyer's phone number -> call and discuss -> confirm through the app.
/// Never an automatic booking, never an online payment.
class ForwardContractsScreen extends StatefulWidget {
  // When embedded as a tab inside another hub (e.g. MarketHubScreen), the
  // parent already provides the AppBar, so this skips its own Scaffold/AppBar
  // and returns just the list — same screen, two presentations.
  final bool embedded;
  const ForwardContractsScreen({super.key, this.embedded = false});

  @override
  State<ForwardContractsScreen> createState() => _ForwardContractsScreenState();
}

class _ForwardContractsScreenState extends State<ForwardContractsScreen> {
  List<Map<String, dynamic>> _contracts = [];
  Map<String, Map<String, dynamic>> _myCommitmentByContract = {};
  bool _loading = true;
  String? _district;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _district = await AuthService.getDistrict();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      InsightsApi.listForwardContracts(district: _district),
      InsightsApi.getMyForwardCommitments(),
    ]);
    if (!mounted) return;
    final list = results[0];
    final mine = results[1];
    final Map<String, Map<String, dynamic>> byContract = {};
    if (mine["success"] == true) {
      for (final row in (mine["data"] as List? ?? [])) {
        final m = Map<String, dynamic>.from(row as Map);
        if (m["myCommitment"] != null) byContract["${m["_id"]}"] = Map<String, dynamic>.from(m["myCommitment"] as Map);
      }
    }
    setState(() {
      _contracts = list["success"] == true ? (list["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList() : [];
      _myCommitmentByContract = byContract;
      _loading = false;
    });
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _expressInterest(Map<String, dynamic> contract) async {
    final remaining = numOf(contract["totalQuantityKg"]) - numOf(contract["committedKg"]);
    final qtyController = TextEditingController(text: priceText(remaining));

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("${tr("How much can you supply?", "ඔබට කොපමණ සැපයිය හැකිද?", "நீங்கள் எவ்வளவு வழங்க முடியும்?")} — ${contract["cropType"]}"),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: tr("Quantity (kg)", "ප්‍රමාණය (කි.ග්‍රෑ.)", "அளவு (கி.கி.)"), helperText: tr("Up to ${priceText(remaining)} kg", "උපරිම කි.ග්‍රෑ. ${priceText(remaining)}", "அதிகபட்சம் ${priceText(remaining)} கி.கி.")),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr("Cancel", "අවලංගු", "ரத்து செய்"))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Express interest", "කැමැත්ත පළ කරන්න", "ஆர்வம் தெரிவி"))),
        ],
      ),
    );
    final qty = double.tryParse(qtyController.text);
    qtyController.dispose();
    if (confirmed != true) return;
    if (qty == null || qty < 1) {
      _toast(tr("Please enter a valid quantity.", "කරුණාකර වලංගු ප්‍රමාණයක් ඇතුළත් කරන්න.", "சரியான அளவை உள்ளிடுங்கள்."));
      return;
    }
    final result = await InsightsApi.expressForwardInterest("${contract["_id"]}", qty);
    if (!mounted) return;
    if (result["success"] == true) {
      final phone = result["buyerPhone"];
      _toast(tr("Interest recorded. Call the buyer to discuss, then confirm.", "කැමැත්ත සටහන් විය. ගැනුම්කරු අමතන්න, පසුව තහවුරු කරන්න.", "ஆர்வம் பதிவு செய்யப்பட்டது. வாங்குபவரை அழைத்து, பின் உறுதிப்படுத்தவும்."));
      if (phone != null && "$phone".isNotEmpty) await callPhone("$phone");
    } else {
      _toast(apiMessage(result));
    }
    _load();
  }

  Future<void> _confirm(Map<String, dynamic> contract, Map<String, dynamic> commitment) async {
    final result = await InsightsApi.confirmForwardCommitment("${contract["_id"]}", "${commitment["_id"]}");
    _toast(result["message"]?.toString() ?? tr("Done.", "සම්පූර්ණයි.", "முடிந்தது."));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            InfoBanner(
              icon: Icons.handshake_rounded,
              text: tr(
                "Buyers here commit to a price BEFORE you plant. Express interest, call to discuss, then confirm — nothing is booked automatically and no payment happens in the app.",
                "මෙහි ගැනුම්කරුවන් ඔබ වැවීමට පෙර මිලක් ප්‍රතිඥා දෙයි. කැමැත්ත පළ කර, අමතන්න, පසුව තහවුරු කරන්න.",
                "இங்கு வாங்குபவர்கள் நீங்கள் நடவு செய்வதற்கு முன்பே விலையை உறுதி செய்கின்றனர். ஆர்வம் தெரிவித்து, அழைத்து, பின் உறுதிப்படுத்துங்கள்.",
              ),
              color: AppColors.indigo,
            ),
            const SizedBox(height: 12),
            if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
            if (!_loading && _contracts.isEmpty)
              emptyState(Icons.handshake_outlined, tr("No open contracts right now", "දැනට විවෘත ගිවිසුම් නැත", "இப்போது திறந்த ஒப்பந்தங்கள் இல்லை"), tr("Check back soon — buyers post these when they want to lock in supply ahead of time.", "නැවත පරීක්ෂා කරන්න.", "மீண்டும் பார்க்கவும்.")),
            ..._contracts.map((c) {
              final remaining = numOf(c["totalQuantityKg"]) - numOf(c["committedKg"]);
              final myCommitment = _myCommitmentByContract["${c["_id"]}"];
              final buyer = c["buyer"] as Map?;
              final buyerName = buyer?["buyerProfile"]?["companyName"] ?? buyer?["fullName"] ?? "";
              return SoftCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text("${c["cropType"]}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                    Text("LKR ${priceText(numOf(c["lockedPricePerKg"]))}/kg", style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.forest)),
                  ]),
                  const SizedBox(height: 4),
                  Text("$buyerName", style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
                  const SizedBox(height: 6),
                  Text(
                    tr(
                      "${priceText(remaining)} kg still needed, by ${DateFormat("d MMM yyyy").format(DateTime.parse("${c["deliverByDate"]}").toLocal())}",
                      "තවමත් කි.ග්‍රෑ. ${priceText(remaining)} අවශ්‍යයි, ${DateFormat("d MMM yyyy").format(DateTime.parse("${c["deliverByDate"]}").toLocal())} වන විට",
                      "இன்னும் ${priceText(remaining)} கி.கி. தேவை, ${DateFormat("d MMM yyyy").format(DateTime.parse("${c["deliverByDate"]}").toLocal())} க்குள்",
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  if ("${c["note"]}".isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text("${c["note"]}", style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted))),
                  const SizedBox(height: 10),
                  if (myCommitment == null)
                    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: remaining > 0 ? () => _expressInterest(c) : null, child: Text(tr("Express interest", "කැමැත්ත පළ කරන්න", "ஆர்வம் தெரிவி"))))
                  else if (myCommitment["status"] == "interested")
                    SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _confirm(c, myCommitment), child: Text(tr("Confirm (after calling)", "තහවුරු කරන්න (අමතා පසු)", "உறுதிப்படுத்து (அழைத்த பின்)"))))
                  else
                    StatusPill(label: tr("Confirmed: ${priceText(numOf(myCommitment["quantityKg"]))} kg", "තහවුරු විය: ${priceText(numOf(myCommitment["quantityKg"]))} කි.ග්‍රෑ.", "உறுதி: ${priceText(numOf(myCommitment["quantityKg"]))} கி.கி."), color: AppColors.forest),
                ]),
              );
            }),
          ],
        ),
      );

    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: Text(tr("Forward Contracts", "අනාගත ගිවිසුම්", "முன்கூட்டிய ஒப்பந்தங்கள்"))),
      body: body,
    );
  }
}
