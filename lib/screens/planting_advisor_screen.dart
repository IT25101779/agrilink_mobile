import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/auth_service.dart';
import '../services/insights_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/ui_kit.dart';

/// DISTRICT PLANTING ADVISOR + ANONYMIZED BENCHMARKING.
///
/// Answers "what should I plant NEXT?" across the whole crop catalogue at
/// once (not just a warning about a crop you already planted), and shows
/// how your own cost-per-kg compares to the district/national average —
/// using only aggregate numbers, never another farmer's name or figures.
class PlantingAdvisorScreen extends StatefulWidget {
  const PlantingAdvisorScreen({super.key});

  @override
  State<PlantingAdvisorScreen> createState() => _PlantingAdvisorScreenState();
}

class _PlantingAdvisorScreenState extends State<PlantingAdvisorScreen> {
  bool _loading = true;
  String? _error;
  String _district = "";
  List<Map<String, dynamic>> _opportunities = [];
  List<Map<String, dynamic>> _avoid = [];
  Map<String, dynamic>? _benchmark;
  String? _benchmarkMessage;

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
    _district = await AuthService.getDistrict() ?? "";
    final results = await Future.wait([
      InsightsApi.getNextSeasonAdvisor(district: _district),
      InsightsApi.getBenchmark(),
    ]);
    if (!mounted) return;
    final advisor = results[0];
    final benchmark = results[1];
    setState(() {
      _loading = false;
      if (advisor["success"] == true) {
        final data = advisor["data"] as Map<String, dynamic>?;
        _opportunities = ((data?["topOpportunities"] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _avoid = ((data?["avoid"] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _error = apiMessage(advisor);
      }
      if (benchmark["success"] == true) {
        _benchmark = benchmark["data"] as Map<String, dynamic>?;
        _benchmarkMessage = benchmark["message"] as String?;
      }
    });
  }

  Widget _cropRow(Map<String, dynamic> c, {required bool isOpportunity}) {
    final roi = numOf(c["expectedRoiPercent"]);
    final farmers = c["farmersGrowingNearby"] ?? 0;
    final color = isOpportunity ? AppColors.forest : AppColors.danger;
    return SoftCard(
      child: Row(children: [
        Container(
          width: 8, height: 44,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${c["cropType"]}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Text(
              isOpportunity
                  ? tr("Expected ROI: ${roi.toStringAsFixed(0)}% · $farmers growing nearby", "බලාපොරොත්තු ලාභය: ${roi.toStringAsFixed(0)}% · ආසන්නයේ ගොවීන් $farmers", "எதிர்பார்க்கும் லாபம்: ${roi.toStringAsFixed(0)}% · அருகில் $farmers விவசாயிகள்")
                  : tr("${c["saturationLevel"] == "high" ? "Crowded — $farmers farmers nearby" : "Expected ROI: ${roi.toStringAsFixed(0)}%"}", "${c["saturationLevel"] == "high" ? "තදබදයි — ආසන්නයේ ගොවීන් $farmers" : "බලාපොරොත්තු ලාභය: ${roi.toStringAsFixed(0)}%"}", "${c["saturationLevel"] == "high" ? "நெரிசல் — அருகில் $farmers விவசாயிகள்" : "எதிர்பார்க்கும் லாபம்: ${roi.toStringAsFixed(0)}%"}"),
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("Planting Advisor", "වැවිලි උපදේශක", "நடவு ஆலோசகர்"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),

          if (!_loading && _benchmark != null) ...[
            Text(tr("How you compare", "ඔබ සසඳන ආකාරය", "நீங்கள் எவ்வாறு ஒப்பிடுகிறீர்கள்"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            SoftCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  tr(
                    "Your cost: LKR ${_benchmark!["myCostPerKgLkr"]}/kg",
                    "ඔබේ වියදම: රු. ${_benchmark!["myCostPerKgLkr"]}/kg",
                    "உங்கள் செலவு: ரூ. ${_benchmark!["myCostPerKgLkr"]}/kg",
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                if (_benchmark!["districtAverageCostPerKgLkr"] != null)
                  Text(
                    tr(
                      "District average: LKR ${_benchmark!["districtAverageCostPerKgLkr"]}/kg — you're cheaper than ${_benchmark!["cheaperThanPercentOfDistrict"]}% of farmers in ${_benchmark!["district"]} (sample of ${_benchmark!["sampleSizeDistrict"]}).",
                      "දිස්ත්‍රික්ක සාමාන්‍යය: රු. ${_benchmark!["districtAverageCostPerKgLkr"]}/kg — ඔබ ${_benchmark!["district"]} හි ගොවීන්ගෙන් ${_benchmark!["cheaperThanPercentOfDistrict"]}%කට වඩා අඩු වියදමක් දරයි.",
                      "மாவட்ட சராசரி: ரூ. ${_benchmark!["districtAverageCostPerKgLkr"]}/kg — ${_benchmark!["district"]} இல் உள்ள விவசாயிகளில் ${_benchmark!["cheaperThanPercentOfDistrict"]}% பேரை விட நீங்கள் குறைவான செலவில் உள்ளீர்கள்.",
                    ),
                    style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
                  ),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          if (!_loading && _benchmark == null && _benchmarkMessage != null)
            InfoBanner(icon: Icons.insights_rounded, text: _benchmarkMessage!, color: AppColors.inkMuted),

          const SizedBox(height: 16),
          Text(tr("Good opportunities to plant next", "වැවීමට හොඳ අවස්ථා", "நடவு செய்ய நல்ல வாய்ப்புகள்"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (!_loading && _opportunities.isEmpty) emptyState(Icons.eco_rounded, tr("Not enough data yet", "තවම දත්ත නොමැත", "இன்னும் தரவு இல்லை"), tr("Set your district in Profile, or check back once more farmers are active.", "ඔබේ දිස්ත්‍රික්කය පැතිකඩේ සකසන්න.", "உங்கள் மாவட்டத்தை சுயவிவரத்தில் அமைக்கவும்.")),
          ..._opportunities.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _cropRow(c, isOpportunity: true))),

          const SizedBox(height: 20),
          Text(tr("Crowded or risky right now", "දැනට තදබද හෝ අවදානම් සහිත", "இப்போது நெரிசலான அல்லது ஆபத்தான"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          ..._avoid.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _cropRow(c, isOpportunity: false))),
        ]),
      ),
    );
  }
}
