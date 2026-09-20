import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/farm_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/ui_kit.dart';

/// Today's official wholesale prices by market, with history, farmer reports and price alerts.
class PriceBoardScreen extends StatefulWidget {
  const PriceBoardScreen({super.key});

  @override
  State<PriceBoardScreen> createState() => _PriceBoardScreenState();
}

class _PriceBoardScreenState extends State<PriceBoardScreen> {
  List<String> _markets = ["Dambulla", "Manning", "Pettah", "Kandy", "Jaffna", "Meegoda"];
  String _market = "Dambulla";
  List<Map<String, dynamic>> _rows = [];
  List<Map<String, dynamic>> _alerts = [];
  String _query = "";
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
    final results = await Future.wait([FarmApi.priceBoard(market: _market), FarmApi.myAlerts()]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (results[0]["success"] == true) {
        _rows = (results[0]["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        final m = results[0]["markets"];
        if (m is List && m.isNotEmpty) _markets = m.map((e) => "$e").toList();
      } else {
        _error = apiMessage(results[0]);
      }
      if (results[1]["success"] == true) _alerts = (results[1]["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    });
  }

  Future<void> _detail(Map<String, dynamic> row) async {
    final crop = "${row["cropType"]}";
    final history = await FarmApi.priceHistory(crop, market: _market);
    if (!mounted) return;
    final points = ((history["data"] as List?) ?? []).map((e) => numOf((e as Map)["pricePerKg"])).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("${cropLabel(crop)} · ${hubName(_market)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text("${tr("Last", "පසුගිය", "கடந்த")} ${points.length} ${tr("days (LKR/kg)", "දින (රු/kg)", "நாட்கள் (ரூ/கி.கி)")}", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: points.length < 2
                ? Center(child: Text(tr("Not enough history yet", "තවම ඉතිහාසය ප්‍රමාණවත් නැත", "இன்னும் போதுமான வரலாறு இல்லை")))
                : LineChart(LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: true),
                    lineBarsData: [LineChartBarData(spots: [for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i])], isCurved: true, barWidth: 3, color: AppColors.forest, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: AppColors.forest.withOpacity(0.12)))],
                  )),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(context); _report(crop); }, icon: const Icon(Icons.edit_note_rounded), label: Text(tr("I saw another price", "මම වෙනත් මිලක් දුටුවා", "நான் வேறு விலை பார்த்தேன்"), style: const TextStyle(fontSize: 12)))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); _alertSheet(crop); }, icon: const Icon(Icons.notifications_active_rounded), label: Text(tr("Alert me", "මට දැනුම් දෙන්න", "எனக்கு எச்சரிக்கை")))),
          ]),
        ]),
      ),
    );
  }

  Future<void> _report(String crop) async {
    final controller = TextEditingController();
    final price = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr("What price did you see?", "ඔබ දුටු මිල කීයද?", "நீங்கள் பார்த்த விலை என்ன?")),
        content: TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number, decoration: InputDecoration(prefixText: "LKR ", suffixText: "/kg", hintText: "${cropLabel(crop)} · ${hubName(_market)}")),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr("Cancel", "අවලංගු", "ரத்து"))), ElevatedButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text.trim())), child: Text(tr("Send", "යවන්න", "அனுப்பு")))],
      ),
    );
    if (price == null) return;
    final result = await FarmApi.reportPrice(crop, _market, price);
    if (!mounted) return;
    showSnack(context, apiMessage(result, tr("Thanks! Your report helps other farmers.", "ස්තූතියි! ඔබේ වාර්තාව අනෙක් ගොවීන්ට උපකාරී වේ.", "நன்றி! உங்கள் அறிக்கை மற்ற விவசாயிகளுக்கு உதவும்.")));
    if (result["success"] == true) _load();
  }

  Future<void> _alertSheet(String crop) async {
    String direction = "above";
    final controller = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${cropLabel(crop)}: ${tr("tell me when the price goes", "මිල වන විට මට කියන්න", "விலை இவ்வாறு ஆகும்போது சொல்")}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Row(children: [
              ChoiceChip(label: Text(tr("Above", "ඉහළ", "மேல்")), selected: direction == "above", onSelected: (_) => setSheet(() => direction = "above")),
              const SizedBox(width: 8),
              ChoiceChip(label: Text(tr("Below", "පහළ", "கீழ்")), selected: direction == "below", onSelected: (_) => setSheet(() => direction = "below")),
            ]),
            const SizedBox(height: 12),
            TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: "LKR ", suffixText: "/kg")),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Save alert", "දැනුම්දීම සුරකින්න", "எச்சரிக்கையைச் சேமி")))),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    final result = await FarmApi.addAlert(crop, direction, double.tryParse(controller.text.trim()) ?? 0);
    if (!mounted) return;
    showSnack(context, result["success"] == true ? tr("Alert saved. You will get a notice when it happens.", "දැනුම්දීම සුරැකිණි. එය සිදුවන විට ඔබට දැනුම් දෙනු ලැබේ.", "எச்சரிக்கை சேமிக்கப்பட்டது. அது நடந்தால் அறிவிப்பு வரும்.") : apiMessage(result));
    if (result["success"] == true) _load();
  }

  Widget _row(Map<String, dynamic> r) {
    final change = r["changePercent"] == null ? null : numOf(r["changePercent"]);
    final up = (change ?? 0) >= 0;
    final color = change == null ? Colors.grey : (up ? AppColors.forest : AppColors.danger);
    return SoftCard(
      onTap: () => _detail(r),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(cropLabel("${r["cropType"]}"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          if (r["communityMedian"] != null) Text("${tr("Farmers saw", "ගොවීන් දුටු", "விவசாயிகள் பார்த்தது")}: LKR ${priceText(numOf(r["communityMedian"]))} (${r["communityReports"]})", style: const TextStyle(fontSize: 11.5, color: AppColors.inkMuted)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text("LKR ${priceText(numOf(r["pricePerKg"]))}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          if (change != null) Row(mainAxisSize: MainAxisSize.min, children: [Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: color, size: 20), Text("${change.abs().toStringAsFixed(1)}%", style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12))]),
        ]),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _rows.where((r) => cropLabel("${r["cropType"]}").toLowerCase().contains(_query.toLowerCase()) || "${r["cropType"]}".toLowerCase().contains(_query.toLowerCase())).toList();
    return Scaffold(
      appBar: AppBar(title: Text(tr("Price board", "මිල පුවරුව", "விலைப் பலகை"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
          Text(tr("Official wholesale prices (LKR per kg). Tap a crop for history, or to set an alert.", "නිල තොග මිල (කිලෝවකට රු). ඉතිහාසය සඳහා හෝ දැනුම්දීමක් තැබීමට බෝගයක් ඔබන්න.", "அதிகாரப்பூர்வ மொத்த விலை (கிலோவுக்கு ரூ). வரலாறு அல்லது எச்சரிக்கைக்கு ஒரு பயிரைத் தட்டவும்."), style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView(scrollDirection: Axis.horizontal, children: _markets.map((m) => Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(label: Text(hubName(m)), selected: _market == m, onSelected: (_) { setState(() => _market = m); _load(); }))).toList()),
          ),
          const SizedBox(height: 10),
          TextField(onChanged: (v) => setState(() => _query = v), decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: tr("Search crops", "බෝග සොයන්න", "பயிர்களைத் தேடு"))),
          const SizedBox(height: 12),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
          if (!_loading && _error == null && shown.isEmpty) emptyState(Icons.show_chart_rounded, tr("No prices yet", "තවම මිල නැත", "இன்னும் விலைகள் இல்லை"), tr("Prices for this market have not been published yet.", "මෙම වෙළඳපොළේ මිල තවම පළ කර නැත.", "இந்தச் சந்தையின் விலைகள் இன்னும் வெளியிடப்படவில்லை.")),
          ...shown.map(_row),
          if (_alerts.isNotEmpty) ...[
            const SizedBox(height: 10),
            SectionHeader(title: tr("My price alerts", "මගේ මිල දැනුම්දීම්", "என் விலை எச்சரிக்கைகள்")),
            ..._alerts.map((a) => SoftCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFFEA580C), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text("${cropLabel("${a["cropType"]}")}: ${a["direction"] == "above" ? tr("above", "ඉහළ", "மேல்") : tr("below", "පහළ", "கீழ்")} LKR ${priceText(numOf(a["thresholdLkr"]))}", style: const TextStyle(fontWeight: FontWeight.w600))),
                    IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () async { await FarmApi.deleteAlert("${a["_id"]}"); _load(); }),
                  ]),
                )),
          ],
        ]),
      ),
    );
  }
}
