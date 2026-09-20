import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/ui_kit.dart';

/// Average rain of the last 5 years for my district, and when to plant for Maha and Yala. Guidance, not a forecast.
class RainPlannerScreen extends StatefulWidget {
  const RainPlannerScreen({super.key});

  @override
  State<RainPlannerScreen> createState() => _RainPlannerScreenState();
}

class _RainPlannerScreenState extends State<RainPlannerScreen> {
  Map<String, dynamic>? _data;
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
    final r = await HelpApi.rainPlanner();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r["success"] == true) {
        _data = Map<String, dynamic>.from(r["data"] as Map);
      } else {
        _error = apiMessage(r);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final months = (_data?["months"] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final advice = (_data?["advice"] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final maxMm = months.isEmpty ? 100.0 : months.map((m) => (m["mm"] as num).toDouble()).reduce((a, b) => a > b ? a : b);
    return Scaffold(
      appBar: AppBar(title: Text(tr("Rain & planting planner", "වැසි හා වගා සැලසුම", "மழை & நடவு திட்டம்"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.cloud_off_rounded, text: _error!, color: AppColors.danger),
          if (_data != null) ...[
            Text("${_data!["district"]} • ${tr("average monthly rain, last", "මාසික සාමාන්‍ය වර්ෂාව, පසුගිය", "சராசரி மாத மழை, கடந்த")} ${_data!["years"]} ${tr("years (mm)", "වසර (මි.මී.)", "ஆண்டுகள் (மி.மீ)")}", style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(BarChartData(
                maxY: maxMm * 1.15,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Padding(padding: const EdgeInsets.only(top: 4), child: Text("${months[v.toInt()]["month"]}".substring(0, 1), style: const TextStyle(fontSize: 11))))),
                ),
                barGroups: [
                  for (int i = 0; i < months.length; i++)
                    BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (months[i]["mm"] as num).toDouble(), width: 14, borderRadius: BorderRadius.circular(4), color: (months[i]["mm"] as num) >= 100 ? AppColors.forest : const Color(0xFFB0BEC5))]),
                ],
              )),
            ),
            const SizedBox(height: 6),
            Text(tr("Green months average 100 mm or more.", "කොළ මාස සාමාන්‍යයෙන් මි.මී. 100+ වේ.", "பச்சை மாதங்கள் சராசரி 100 மி.மீ+."), style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
            const SizedBox(height: 14),
            ...advice.map((a) => SoftCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a["season"] == "maha" ? tr("Maha season", "මහ කන්නය", "பெரும்போகம்") : tr("Yala season", "යල කන්නය", "சிறுபோகம்"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text("${tr("Best month to start", "ආරම්භ කිරීමට හොඳම මාසය", "தொடங்க சிறந்த மாதம்")}: ${a["plantMonth"]} (${a["rainMm"]} mm)", style: const TextStyle(fontSize: 14, color: AppColors.forest, fontWeight: FontWeight.w700)),
                    if (a["needsIrrigation"] == true) Text(tr("Plan for irrigation - this month is usually dry.", "වාරිමාර්ග සලකන්න - මෙම මාසය සාමාන්‍යයෙන් වියළියි.", "நீர்ப்பாசனம் திட்டமிடவும் - இந்த மாதம் பொதுவாக வறண்டது."), style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                  ]),
                )),
            InfoBanner(icon: Icons.info_outline_rounded, text: "${_data!["note"]}"),
          ],
        ]),
      ),
    );
  }
}
