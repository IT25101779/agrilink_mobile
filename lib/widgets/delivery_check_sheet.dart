import 'package:flutter/material.dart';
import '../localization/chat_labels.dart';
import '../localization/tr.dart';
import '../services/auth_service.dart';
import '../services/farm_api.dart';
import '../theme/app_theme.dart';
import 'farm_common.dart';
import 'ui_kit.dart';

/// "If I send this crop from my district, how fresh will it be when it reaches each market?"
Future<void> showDeliveryCheckSheet(BuildContext context, {String? cropType}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (_) => _DeliveryCheckSheet(initialCrop: cropType),
  );
}

class _DeliveryCheckSheet extends StatefulWidget {
  final String? initialCrop;
  const _DeliveryCheckSheet({this.initialCrop});

  @override
  State<_DeliveryCheckSheet> createState() => _DeliveryCheckSheetState();
}

class _DeliveryCheckSheetState extends State<_DeliveryCheckSheet> {
  late String _crop;
  String? _district;
  int _ageDays = 0;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    final crops = allCropNames();
    _crop = widget.initialCrop != null && crops.contains(widget.initialCrop) ? widget.initialCrop! : (crops.contains("Tomato") ? "Tomato" : crops.first);
    AuthService.getDistrict().then((d) {
      if (mounted && d != null && kChatDistricts.contains(d)) setState(() => _district = d);
    });
  }

  Future<void> _check() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await FarmApi.deliveryEstimate(cropType: _crop, harvestDate: DateTime.now().subtract(Duration(days: _ageDays)), district: _district);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result["success"] == true) {
        _result = Map<String, dynamic>.from(result["data"] as Map);
      } else {
        _error = apiMessage(result);
      }
    });
  }

  Color _riskColor(String r) => r == "good" ? AppColors.forest : r == "ok" ? const Color(0xFFCA8A04) : r == "risky" ? const Color(0xFFEA580C) : AppColors.danger;

  String _riskText(String r) {
    switch (r) {
      case "good":
        return tr("Arrives fresh", "නැවුම්ව ලැබේ", "புதிதாகச் சேரும்");
      case "ok":
        return tr("Fine, but sell soon", "හරි, නමුත් ඉක්මනින් විකුණන්න", "பரவாயில்லை, விரைவில் விற்கவும்");
      case "risky":
        return tr("Risky — use a cool truck", "අවදානම් — සිසිල් ට්‍රක් රථයක් යොදන්න", "ஆபத்து — குளிர் லாரி பயன்படுத்துங்கள்");
      default:
        return tr("Too long — will spoil", "ඉතා දිගයි — නරක් වේ", "மிக நீளம் — கெட்டுவிடும்");
    }
  }

  String _ageLabel(int d) => d == 0 ? tr("Today", "අද", "இன்று") : tr("$d d ago", "දින $d කට පෙර", "$d நாள் முன்");

  @override
  Widget build(BuildContext context) {
    final options = ((_result?["options"] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(tr("How fresh will it arrive?", "එය කෙතරම් නැවුම්ව ලැබේද?", "எவ்வளவு புத்துணர்ச்சியுடன் சென்றடையும்?"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _crop,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr("Crop", "බෝගය", "பயிர்")),
            items: allCropNames().map((c) => DropdownMenuItem(value: c, child: Text(cropLabel(c)))).toList(),
            onChanged: (v) => setState(() => _crop = v ?? _crop),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _district,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr("Your district", "ඔබේ දිස්ත්‍රික්කය", "உங்கள் மாவட்டம்")),
            items: kChatDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) => setState(() => _district = v),
          ),
          const SizedBox(height: 12),
          Text(tr("Harvested", "අස්වනු නෙළූ", "அறுவடை"), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [0, 1, 2, 3, 5].map((d) => ChoiceChip(label: Text(_ageLabel(d)), selected: _ageDays == d, onSelected: (_) => setState(() => _ageDays = d))).toList()),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _loading ? null : _check, child: _loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(tr("Check freshness", "නැවුම්බව පරීක්ෂා කරන්න", "புத்துணர்ச்சியைச் சரிபார்")))),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(_error!, style: const TextStyle(color: AppColors.danger))),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 18),
            ...options.asMap().entries.map((entry) {
              final o = entry.value;
              final pct = (o["percentRemainingAtArrival"] as num).toInt();
              final color = _riskColor("${o["risk"]}");
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text("${entry.key == 0 ? "★ " : ""}${hubName("${o["hub"]}")}", style: TextStyle(fontWeight: FontWeight.w800, color: entry.key == 0 ? AppColors.forest : null))),
                    Text("$pct%", style: TextStyle(fontWeight: FontWeight.w800, color: color)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: pct / 100, minHeight: 7, color: color, backgroundColor: color.withOpacity(0.15))),
                  const SizedBox(height: 3),
                  Text("${o["distanceKm"]} km · ${priceText(numOf(o["transitHours"]))} h · ${_riskText("${o["risk"]}")}", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                ]),
              );
            }),
            Text(tr("Estimate for an open truck. Real time depends on traffic and stops.", "විවෘත ට්‍රක් රථයක් සඳහා ඇස්තමේන්තුවකි. සැබෑ කාලය ගමනාගමනය හා නැවතුම් මත රඳා පවතී.", "திறந்த லாரிக்கான மதிப்பீடு. உண்மையான நேரம் போக்குவரத்து மற்றும் நிறுத்தங்களைப் பொறுத்தது."), style: const TextStyle(fontSize: 11.5, color: AppColors.inkMuted)),
          ],
        ]),
      ),
    );
  }
}
