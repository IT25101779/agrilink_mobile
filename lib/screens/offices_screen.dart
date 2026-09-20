import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/auth_service.dart';
import '../services/help_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/ui_kit.dart';

/// Where to get real help nearby: Agrarian Service Centres, extension officers, cooperatives.
class OfficesScreen extends StatefulWidget {
  const OfficesScreen({super.key});

  @override
  State<OfficesScreen> createState() => _OfficesScreenState();
}

class _OfficesScreenState extends State<OfficesScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String _district = "";

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
    final r = await HelpApi.offices(district: _district);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r["success"] == true) {
        _items = (r["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _error = apiMessage(r);
      }
    });
  }

  String _kind(String k) {
    switch (k) {
      case "agrarian_service_centre":
        return tr("Agrarian Service Centre", "ගොවිජන සේවා මධ්‍යස්ථානය", "விவசாய சேவை மையம்");
      case "extension_officer":
        return tr("Extension officer", "ව්‍යාප්ති නිලධාරියා", "விரிவாக்க அலுவலர்");
      case "cooperative":
        return tr("Cooperative society", "සමුපකාර සමිතිය", "கூட்டுறவு சங்கம்");
      case "research_station":
        return tr("Research station", "පර්යේෂණ ආයතනය", "ஆராய்ச்சி நிலையம்");
      case "government_office":
        return tr("Government office", "රජයේ කාර්යාලය", "அரசு அலுவலகம்");
      default:
        return tr("Other", "වෙනත්", "பிற");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("Get help near me", "ආසන්න උපකාර", "அருகில் உதவி"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
          Text(_district.isEmpty ? tr("Set your district in Profile to see offices near you.", "ඔබේ දිස්ත්‍රික්කය පැතිකඩේ සකසන්න.", "உங்கள் மாவட்டத்தை சுயவிவரத்தில் அமைக்கவும்.") : "${tr("Offices in", "කාර්යාල:", "அலுவலகங்கள்:")} $_district", style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
          const SizedBox(height: 10),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
          if (!_loading && _error == null && _items.isEmpty) emptyState(Icons.location_city_rounded, tr("Nothing listed yet", "තවම කිසිවක් නැත", "இன்னும் எதுவும் இல்லை"), tr("The AgriLink team is adding offices district by district.", "AgriLink කණ්ඩායම දිස්ත්‍රික්ක අනුව කාර්යාල එකතු කරයි.", "AgriLink குழு மாவட்டம் வாரியாக அலுவலகங்களை சேர்க்கிறது.")),
          ..._items.map((o) => SoftCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("${o["name"]}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(_kind("${o["kind"]}"), style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  if ("${o["address"]}".isNotEmpty) Text("${o["address"]}", style: const TextStyle(fontSize: 13)),
                  if ("${o["hours"]}".isNotEmpty) Text("${o["hours"]}", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  if (o["isSample"] == true) Padding(padding: const EdgeInsets.only(top: 4), child: Text(tr("Sample entry - not a real contact yet.", "නියැදි ඇතුළත් කිරීමකි - තවම සැබෑ සම්බන්ධතාවයක් නොවේ.", "மாதிரி பதிவு - உண்மையான தொடர்பு அல்ல."), style: const TextStyle(fontSize: 11, color: AppColors.danger))),
                  if ("${o["phone"]}".isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: OutlinedButton.icon(onPressed: () => callPhone("${o["phone"]}"), icon: const Icon(Icons.call_rounded), label: Text("${o["phone"]}"))),
                ]),
              )),
        ]),
      ),
    );
  }
}
