import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/farm_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/ui_kit.dart';

/// The farmer's own money book: what I spent, what I earned, what is left.
class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;
  String? _error;

  static const _costCategories = ["seeds", "fertilizer", "pesticide", "labour", "water", "transport", "equipment", "other"];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String categoryLabel(String c) {
    switch (c) {
      case "seeds":
        return tr("Seeds", "බීජ", "விதை");
      case "fertilizer":
        return tr("Fertilizer", "පොහොර", "உரம்");
      case "pesticide":
        return tr("Pesticide", "පළිබෝධනාශක", "பூச்சிக்கொல்லி");
      case "labour":
        return tr("Labour", "ශ්‍රමය", "தொழிலாளர்");
      case "water":
        return tr("Water", "ජලය", "நீர்");
      case "transport":
        return tr("Transport", "ප්‍රවාහනය", "போக்குவரத்து");
      case "equipment":
        return tr("Equipment", "උපකරණ", "உபகரணங்கள்");
      case "sale":
        return tr("Sale", "විකිණීම", "விற்பனை");
      default:
        return tr("Other", "වෙනත්", "மற்றவை");
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait([FarmApi.ledgerSummary(), FarmApi.ledgerList()]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (results[0]["success"] == true) _summary = Map<String, dynamic>.from(results[0]["data"] as Map);
      if (results[1]["success"] == true) {
        _entries = (results[1]["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _error = apiMessage(results[1]);
      }
    });
  }

  Future<void> _add() async {
    String type = "expense";
    String category = "seeds";
    String crop = "General";
    DateTime date = DateTime.now();
    final amount = TextEditingController();
    final note = TextEditingController();
    String? error;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ChoiceChip(label: Text(tr("Cost", "වියදම", "செலவு")), selected: type == "expense", onSelected: (_) => setSheet(() => type = "expense")),
                const SizedBox(width: 8),
                ChoiceChip(label: Text(tr("Income", "ආදායම", "வருமானம்")), selected: type == "income", onSelected: (_) => setSheet(() => type = "income")),
              ]),
              const SizedBox(height: 14),
              TextField(controller: amount, autofocus: true, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr("Amount (LKR)", "මුදල (රු)", "தொகை (ரூ)"), prefixText: "LKR ")),
              if (type == "expense") ...[
                const SizedBox(height: 12),
                Wrap(spacing: 8, children: _costCategories.map((c) => ChoiceChip(label: Text(categoryLabel(c), style: const TextStyle(fontSize: 12)), selected: category == c, onSelected: (_) => setSheet(() => category = c))).toList()),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: crop,
                isExpanded: true,
                decoration: InputDecoration(labelText: tr("For which crop?", "කුමන බෝගයටද?", "எந்தப் பயிருக்கு?")),
                items: [DropdownMenuItem(value: "General", child: Text(tr("General / whole farm", "පොදු / සම්පූර්ණ ගොවිපල", "பொது / முழு பண்ணை"))), ...allCropNames().map((c) => DropdownMenuItem(value: c, child: Text(cropLabel(c))))],
                onChanged: (v) => setSheet(() => crop = v ?? crop),
              ),
              const SizedBox(height: 12),
              TextField(controller: note, maxLength: 120, decoration: InputDecoration(labelText: tr("Note (optional)", "සටහන (විකල්ප)", "குறிப்பு (விருப்பம்)"))),
              Row(children: [
                TextButton.icon(
                  icon: const Icon(Icons.event_rounded),
                  label: Text("${date.day}/${date.month}/${date.year}"),
                  onPressed: () async {
                    final d = await showDatePicker(context: context, initialDate: date, firstDate: DateTime.now().subtract(const Duration(days: 900)), lastDate: DateTime.now());
                    if (d != null) setSheet(() => date = d);
                  },
                ),
              ]),
              if (error != null) Text(error!, style: const TextStyle(color: AppColors.danger)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await FarmApi.ledgerAdd({"type": type, "category": category, "amountLkr": double.tryParse(amount.text.trim()) ?? 0, "cropType": crop, "note": note.text.trim(), "date": date.toIso8601String()});
                    if (result["success"] == true) {
                      if (context.mounted) Navigator.pop(context, true);
                    } else {
                      setSheet(() => error = apiMessage(result));
                    }
                  },
                  child: Text(tr("Save", "සුරකින්න", "சேமி")),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    if (ok == true) _load();
  }

  Widget _stat(String label, num value, Color color) => Expanded(
        child: SoftCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(lkr(value), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color))),
          ]),
        ),
      );

  Widget _bars(Map<String, dynamic> byCategory) {
    final entries = byCategory.entries.map((e) => MapEntry(e.key, numOf(e.value))).toList()..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return const SizedBox.shrink();
    final max = entries.first.value;
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr("Where the money goes", "මුදල් යන්නේ කොහේද", "பணம் எங்கே போகிறது"), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ...entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Expanded(child: Text(categoryLabel(e.key), style: const TextStyle(fontSize: 12.5))), Text(lkr(e.value), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))]),
                const SizedBox(height: 3),
                ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: max == 0 ? 0 : e.value / max, minHeight: 6, color: const Color(0xFFEA580C), backgroundColor: const Color(0xFFEA580C).withOpacity(0.12))),
              ]),
            )),
      ]),
    );
  }

  Widget _crops(List crops) {
    if (crops.isEmpty) return const SizedBox.shrink();
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr("Profit by crop", "බෝගය අනුව ලාභය", "பயிர் வாரியாக லாபம்"), style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        ...crops.map((c) {
          final profit = numOf(c["profit"]);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: Text(c["cropType"] == "General" ? tr("General", "පොදු", "பொது") : cropLabel("${c["cropType"]}"), style: const TextStyle(fontSize: 13))),
              Text("${profit >= 0 ? "+" : ""}${lkr(profit)}", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: profit >= 0 ? AppColors.forest : AppColors.danger)),
            ]),
          );
        }),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profit = numOf(_summary["profit"]);
    return Scaffold(
      appBar: AppBar(title: Text(tr("Farm ledger", "ගොවිපල ගිණුම්", "பண்ணைக் கணக்கு"))),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add_rounded), label: Text(tr("Add entry", "සටහනක් එක් කරන්න", "பதிவைச் சேர்"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
                if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
                if (_entries.isEmpty && _error == null) emptyState(Icons.account_balance_wallet_outlined, tr("Start your money book", "ඔබේ මුදල් පොත ආරම්භ කරන්න", "உங்கள் பணப் புத்தகத்தைத் தொடங்குங்கள்"), tr("Write down what you spend and earn. It shows your real profit — and helps when you ask for a loan.", "ඔබ වියදම් කරන හා උපයන දේ ලියන්න. එය ඔබේ සැබෑ ලාභය පෙන්වයි — ණයක් ඉල්ලන විට ද උපකාරී වේ.", "நீங்கள் செலவழிப்பதையும் சம்பாதிப்பதையும் எழுதுங்கள். இது உங்கள் உண்மையான லாபத்தைக் காட்டும் — கடன் கேட்கும்போதும் உதவும்.")),
                if (_entries.isNotEmpty) ...[
                  Row(children: [
                    _stat(tr("Income", "ආදායම", "வருமானம்"), numOf(_summary["income"]), AppColors.forest),
                    const SizedBox(width: 8),
                    _stat(tr("Costs", "වියදම්", "செலவுகள்"), numOf(_summary["expense"]), const Color(0xFFEA580C)),
                    const SizedBox(width: 8),
                    _stat(tr("Profit", "ලාභය", "லாபம்"), profit, profit >= 0 ? AppColors.forest : AppColors.danger),
                  ]),
                  const SizedBox(height: 14),
                  _bars(Map<String, dynamic>.from((_summary["byCategory"] as Map?) ?? {})),
                  _crops((_summary["crops"] as List?) ?? []),
                  const SizedBox(height: 4),
                  SectionHeader(title: tr("All entries", "සියලු සටහන්", "அனைத்துப் பதிவுகள்")),
                  ..._entries.map((e) {
                    final income = e["type"] == "income";
                    return Dismissible(
                      key: ValueKey(e["id"]),
                      direction: DismissDirection.endToStart,
                      background: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.only(right: 20), alignment: Alignment.centerRight, decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete_rounded, color: Colors.white)),
                      confirmDismiss: (_) async {
                        final r = await FarmApi.ledgerDelete("${e["id"]}");
                        if (r["success"] == true) {
                          _load();
                          return true;
                        }
                        if (mounted) showSnack(context, apiMessage(r));
                        return false;
                      },
                      child: SoftCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Container(width: 36, height: 36, decoration: BoxDecoration(color: (income ? AppColors.forest : const Color(0xFFEA580C)).withOpacity(0.12), shape: BoxShape.circle), child: Icon(income ? Icons.south_west_rounded : Icons.north_east_rounded, size: 18, color: income ? AppColors.forest : const Color(0xFFEA580C))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("${categoryLabel("${e["category"]}")}${e["cropType"] != "General" ? " · ${cropLabel("${e["cropType"]}")}" : ""}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                            Text("${"${e["date"]}".substring(0, 10)}${"${e["note"]}".isNotEmpty ? " · ${e["note"]}" : ""}", maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: AppColors.inkMuted)),
                          ])),
                          Text("${income ? "+" : "-"}${groupedNumber(numOf(e["amountLkr"]))}", style: TextStyle(fontWeight: FontWeight.w800, color: income ? AppColors.forest : const Color(0xFFEA580C))),
                        ]),
                      ),
                    );
                  }),
                ],
              ]),
      ),
    );
  }
}
