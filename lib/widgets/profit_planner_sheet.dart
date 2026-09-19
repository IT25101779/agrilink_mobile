import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../localization/tr.dart';
import '../services/insights_api.dart';
import '../theme/app_theme.dart';
import 'shimmer_loading.dart';
import 'ui_kit.dart';

/// PROFIT PLANNER — "will this crop make money?" for one crop and plot size.
///
/// Shows a LOW / EXPECTED / HIGH profit range, the break-even price and the
/// risks. The yield, cost and price figures are typical estimates and the
/// farmer can change any of them and recalculate.
class ProfitPlannerSheet extends StatefulWidget {
  final String cropType;
  final double acres;

  const ProfitPlannerSheet({super.key, required this.cropType, required this.acres});

  static Future<void> show(BuildContext context, {required String cropType, required double acres}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ProfitPlannerSheet(cropType: cropType, acres: acres),
      ),
    );
  }

  @override
  State<ProfitPlannerSheet> createState() => _ProfitPlannerSheetState();
}

class _ProfitPlannerSheetState extends State<ProfitPlannerSheet> {
  final _yieldController = TextEditingController();
  final _costController = TextEditingController();
  final _priceController = TextEditingController();

  Map<String, dynamic>? _plan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _yieldController.dispose();
    _costController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  /// [useEdits] false = typical figures; true = the numbers typed in the boxes.
  Future<void> _load({bool useEdits = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await InsightsApi.getProfitPlan(
      widget.cropType,
      acres: widget.acres,
      yieldKgPerAcre: useEdits ? double.tryParse(_yieldController.text) : null,
      costPerAcre: useEdits ? double.tryParse(_costController.text) : null,
      pricePerKg: useEdits ? double.tryParse(_priceController.text) : null,
    );
    if (!mounted) return;
    if (result["success"] == true && result["data"] is Map) {
      final plan = Map<String, dynamic>.from(result["data"] as Map);
      final assumptions = plan["assumptions"] is Map ? Map<String, dynamic>.from(plan["assumptions"] as Map) : null;
      setState(() {
        _plan = plan;
        _loading = false;
        if (assumptions != null) {
          _yieldController.text = priceText(numOf(assumptions["yieldKgPerAcre"]));
          _costController.text = priceText(numOf(assumptions["costPerAcre"]));
          _priceController.text = assumptions["expectedPricePerKg"] == null ? "" : priceText(numOf(assumptions["expectedPricePerKg"]));
        }
      });
    } else {
      setState(() {
        _loading = false;
        _error = result["message"]?.toString() ?? tr("Could not build the estimate.", "ඇස්තමේන්තුව සැකසිය නොහැකි විය.");
      });
    }
  }

  Color _verdictColor(String verdict) {
    switch (verdict) {
      case "good":
      case "fair":
        return AppColors.forest;
      case "marginal":
        return AppColors.gold;
      case "loss":
        return AppColors.danger;
      default:
        return AppColors.indigo;
    }
  }

  String _verdictLabel(String verdict) {
    switch (verdict) {
      case "good":
        return tr("Strong return", "හොඳ ප්‍රතිලාභයක්");
      case "fair":
        return tr("Fair return", "සාධාරණ ප්‍රතිලාභයක්");
      case "marginal":
        return tr("Thin margin", "අඩු ලාභයක්");
      case "loss":
        return tr("Likely loss", "පාඩුවක් වීමට ඉඩ ඇත");
      default:
        return tr("Enter your expected price", "ඔබ බලාපොරොත්තු වන මිල ඇතුළත් කරන්න");
    }
  }

  String _signedLkr(num value) => value < 0 ? "-${lkr(value.abs())}" : lkr(value);

  Widget _scenarioBox(String label, Map<String, dynamic> s, Color accent) {
    final profit = numOf(s["profitLkr"]);
    final color = profit < 0 ? AppColors.danger : accent;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: tintOf(context, color), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: mutedOf(context))),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(_signedLkr(profit), style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: color)),
            ),
            Text("${numOf(s["roiPercent"]).toStringAsFixed(0)}% ROI", style: TextStyle(fontSize: 10.5, color: mutedOf(context))),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: mutedOf(context)))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, String suffix, bool edited) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
          helperText: edited ? tr("Edited by you", "ඔබ වෙනස් කළා") : tr("Typical estimate", "සාමාන්‍ය ඇස්තමේන්තුව"),
          isDense: true,
        ),
      ),
    );
  }

  Widget _body(Map<String, dynamic> plan) {
    if (plan["supported"] != true) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: InfoBanner(
          icon: Icons.info_outline_rounded,
          color: AppColors.gold,
          text: tr(
            "A profit estimate for one crop cycle is only available for annual crops. Tree and plantation crops take several years to pay back.",
            "එක් බෝග වටයක ලාභ ඇස්තමේන්තුවක් ලබා ගත හැක්කේ වාර්ෂික බෝග සඳහා පමණි. ගස් සහ වැවිලි බෝග ආපසු ගෙවීමට වසර ගණනක් ගත වේ.",
          ),
        ),
      );
    }

    final verdict = "${plan["verdict"]}";
    final color = _verdictColor(verdict);
    final scenarios = plan["scenarios"] is Map ? Map<String, dynamic>.from(plan["scenarios"] as Map) : null;
    final expected = scenarios != null ? Map<String, dynamic>.from(scenarios["expected"] as Map) : null;
    // Non-null copy for the block below, where `scenarios` is known to exist.
    final exp = expected ?? <String, dynamic>{};
    final assumptions = Map<String, dynamic>.from(plan["assumptions"] as Map);
    final harvest = DateTime.tryParse("${plan["harvestDate"]}");
    final notes = (plan["riskNotes"] as List? ?? []).map((n) => "$n").toList();
    final priceConfidence = "${plan["priceConfidence"]}";

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tintOf(context, color),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StatusPill(label: _verdictLabel(verdict), color: color),
              const SizedBox(height: 10),
              if (expected != null) ...[
                Text(tr("Expected profit", "බලාපොරොත්තු වන ලාභය"), style: TextStyle(fontSize: 12, color: mutedOf(context))),
                Text(_signedLkr(numOf(expected["profitLkr"])), style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: numOf(expected["profitLkr"]) < 0 ? AppColors.danger : AppColors.forest)),
                Text(
                  "${numOf(expected["roiPercent"]).toStringAsFixed(0)}% ${tr("return on cost", "වියදමට ප්‍රතිලාභය")}${harvest != null ? " · ${tr("harvest around", "අස්වැන්න")} ${DateFormat("d MMM yyyy").format(harvest.toLocal())}" : ""}",
                  style: TextStyle(fontSize: 12, color: mutedOf(context)),
                ),
              ] else
                Text(
                  tr("To break even you must sell at about LKR ${priceText(numOf(plan["breakEvenPricePerKg"]))}/kg. Enter the price you expect below.",
                      "පාඩුවක් නොවීමට ඔබ කි.ග්‍රෑ. එකක් LKR ${priceText(numOf(plan["breakEvenPricePerKg"]))} පමණ ගණනට විකිණිය යුතුයි. ඔබ බලාපොරොත්තු වන මිල පහත ඇතුළත් කරන්න."),
                  style: const TextStyle(fontSize: 13.5, height: 1.4),
                ),
            ],
          ),
        ),
        if (scenarios != null) ...[
          const SizedBox(height: 14),
          Text(tr("What could happen", "සිදුවිය හැක්කේ කුමක්ද"), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(
            children: [
              _scenarioBox(tr("Poor season", "දුර්වල කන්නය"), Map<String, dynamic>.from(scenarios["low"] as Map), AppColors.gold),
              const SizedBox(width: 8),
              _scenarioBox(tr("Expected", "බලාපොරොත්තු"), exp, AppColors.forest),
              const SizedBox(width: 8),
              _scenarioBox(tr("Good season", "හොඳ කන්නය"), Map<String, dynamic>.from(scenarios["high"] as Map), AppColors.forest),
            ],
          ),
          const SizedBox(height: 14),
          SoftCard(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                _row(tr("Harvest to sell", "විකිණීමට අස්වැන්න"), "${priceText(numOf(exp["sellableKg"]))} kg"),
                _row(tr("Price at harvest time", "අස්වැන්න නෙළන විට මිල"), "LKR ${priceText(numOf(exp["pricePerKg"]))}/kg"),
                _row(tr("Expected income", "බලාපොරොත්තු වන ආදායම"), lkr(numOf(exp["revenueLkr"]))),
                _row(tr("Total cost", "මුළු වියදම"), lkr(numOf(exp["costLkr"]))),
                _row(tr("Break-even price", "පාඩුවක් නොවන මිල"), "LKR ${priceText(numOf(plan["breakEvenPricePerKg"]))}/kg"),
              ],
            ),
          ),
          if (assumptions["priceSource"] == "forecast")
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                tr("Price comes from the market forecast (${priceConfidence == "high" ? "high" : priceConfidence == "medium" ? "medium" : "low"} confidence).",
                    "මිල ලබාගත්තේ වෙළඳපොළ අනාවැකියෙනි."),
                style: TextStyle(fontSize: 11.5, color: mutedOf(context)),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(tr("Your numbers", "ඔබේ සංඛ්‍යා"), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          tr("These are typical estimates. Change them to match your own farm, then recalculate.", "මේවා සාමාන්‍ය ඇස්තමේන්තු වේ. ඔබේ ගොවිපළට ගැළපෙන පරිදි වෙනස් කර නැවත ගණනය කරන්න."),
          style: TextStyle(fontSize: 12, color: mutedOf(context), height: 1.35),
        ),
        const SizedBox(height: 10),
        _field(_yieldController, tr("Harvest per acre", "අක්කරයකට අස්වැන්න"), "kg", assumptions["yieldIsEdited"] == true),
        _field(_costController, tr("Cost per acre", "අක්කරයකට වියදම"), "LKR", assumptions["costIsEdited"] == true),
        _field(_priceController, tr("Price you expect", "ඔබ බලාපොරොත්තු වන මිල"), "LKR/kg", assumptions["priceSource"] == "farmer"),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _loading ? null : () => _load(useEdits: true),
                icon: const Icon(Icons.calculate_rounded, size: 18),
                label: Text(tr("Recalculate", "නැවත ගණනය කරන්න")),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _loading ? null : () => _load(),
              child: Text(tr("Reset", "යළි පිහිටුවන්න")),
            ),
          ],
        ),
        if (notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(tr("Things to watch", "අවධානය යොමු කළ යුතු දේ"), style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          ...notes.map(
            (note) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 8),
                    child: Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.gold),
                  ),
                  Expanded(child: Text(note, style: const TextStyle(fontSize: 12.5, height: 1.4))),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          tr(
            "Planning estimate only. Real yield, cost and price vary by farm, season and inputs. Not a guarantee of profit.",
            "සැලසුම් ඇස්තමේන්තුවක් පමණි. සැබෑ අස්වැන්න, වියදම සහ මිල ගොවිපළ, කන්නය සහ යෙදවුම් අනුව වෙනස් වේ. ලාභයක් පිළිබඳ සහතිකයක් නොවේ.",
          ),
          style: TextStyle(fontSize: 11, color: mutedOf(context), height: 1.4),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_loading && _plan == null) {
      content = ListView(padding: const EdgeInsets.all(20), children: const [ShimmerCard(), ShimmerCard(), ShimmerCard()]);
    } else if (_error != null && _plan == null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.inkMuted),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => _load(), child: Text(tr("Try again", "නැවත උත්සාහ කරන්න"))),
            ],
          ),
        ),
      );
    } else {
      content = Stack(
        children: [
          _body(_plan!),
          if (_loading) const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 3)),
        ],
      );
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: borderOf(context), borderRadius: BorderRadius.circular(4))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: AppColors.forest),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${tr("Profit estimate", "ලාභ ඇස්තමේන්තුව")} · ${widget.cropType}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text("${priceText(widget.acres)} ${tr(widget.acres == 1 ? "acre" : "acres", "අක්කර")}", style: TextStyle(fontSize: 12.5, color: mutedOf(context))),
                ],
              ),
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
