import 'dart:convert';
import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import '../services/share_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/help_widgets.dart';
import '../widgets/ui_kit.dart';

/// Crop damage with photos: an evidence report you can hand to an insurer or an officer.
class DamageScreen extends StatefulWidget {
  const DamageScreen({super.key});

  @override
  State<DamageScreen> createState() => _DamageScreenState();
}

class _DamageScreenState extends State<DamageScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await HelpApi.damageList();
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

  String _cause(String c) {
    switch (c) {
      case "drought":
        return tr("Drought", "නියඟය", "வறட்சி");
      case "flood":
        return tr("Flood", "ගංවතුර", "வெள்ளம்");
      case "heavy_rain":
        return tr("Heavy rain", "අධික වර්ෂාව", "கனமழை");
      case "pest":
        return tr("Pests", "පළිබෝධ", "பூச்சிகள்");
      case "disease":
        return tr("Disease", "රෝග", "நோய்");
      case "wildlife":
        return tr("Wild animals", "වන සතුන්", "வனவிலங்குகள்");
      case "fire":
        return tr("Fire", "ගිනි", "தீ");
      default:
        return tr("Other", "වෙනත්", "பிற");
    }
  }

  Future<void> _add() async {
    String crop = allCropNames().first, cause = "heavy_rain";
    final acres = TextEditingController(), loss = TextEditingController(), desc = TextEditingController();
    DateTime when = DateTime.now();
    final photos = <String>[];
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr("Record crop damage", "බෝග හානිය වාර්තා කරන්න", "பயிர் சேதத்தைப் பதிவு செய்யவும்"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(value: crop, decoration: InputDecoration(labelText: tr("Crop", "බෝගය", "பயிர்"), border: const OutlineInputBorder()), items: allCropNames().map((c) => DropdownMenuItem(value: c, child: Text(cropLabel(c)))).toList(), onChanged: (v) => setS(() => crop = v ?? crop)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 4, children: [for (final c in ["drought", "flood", "heavy_rain", "pest", "disease", "wildlife", "fire", "other"]) ChoiceChip(label: Text(_cause(c)), selected: cause == c, onSelected: (_) => setS(() => cause = c))]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: acres, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr("Acres affected", "බලපෑ අක්කර", "பாதித்த ஏக்கர்"), border: const OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: loss, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr("Loss estimate LKR", "අලාභ ඇස්තමේන්තුව රු.", "இழப்பு மதிப்பீடு ரூ."), border: const OutlineInputBorder()))),
              ]),
              ListTile(contentPadding: EdgeInsets.zero, title: Text("${tr("Date it happened", "සිදු වූ දිනය", "நடந்த நாள்")}: ${when.toIso8601String().substring(0, 10)}"), trailing: const Icon(Icons.calendar_today_rounded), onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: when, firstDate: DateTime.now().subtract(const Duration(days: 700)), lastDate: DateTime.now());
                if (d != null) setS(() => when = d);
              }),
              TextField(controller: desc, maxLines: 2, maxLength: 400, decoration: InputDecoration(labelText: tr("What happened", "සිදු වූයේ කුමක්ද", "என்ன நடந்தது"), border: const OutlineInputBorder())),
              Wrap(spacing: 8, children: [
                for (final p in photos) ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(base64Decode(p), width: 64, height: 64, fit: BoxFit.cover)),
                if (photos.length < 3) OutlinedButton.icon(onPressed: () async {
                  final p = await askAndPickPhoto(ctx);
                  if (p == null) return;
                  if (p == "TOO_BIG") return showSnack(ctx, tr("That photo is too large.", "ඡායාරූපය විශාල වැඩියි.", "படம் மிகப் பெரியது."));
                  setS(() => photos.add(p));
                }, icon: const Icon(Icons.add_a_photo_rounded), label: Text("${tr("Photo", "ඡායාරූපය", "படம்")} ${photos.length}/3")),
              ]),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr("Save report", "වාර්තාව සුරකින්න", "அறிக்கையைச் சேமி")))),
            ]),
          ),
        ),
      ),
    );
    if (go != true) return;
    final r = await HelpApi.addDamage({"cropType": crop, "cause": cause, "acresAffected": double.tryParse(acres.text.trim()) ?? 0, "estimatedLossLkr": double.tryParse(loss.text.trim()) ?? 0, "happenedOn": when.toIso8601String(), "description": desc.text.trim(), "photos": photos});
    if (!mounted) return;
    showSnack(context, r["success"] == true ? tr("Report saved.", "වාර්තාව සුරකින ලදි.", "அறிக்கை சேமிக்கப்பட்டது.") : apiMessage(r));
    if (r["success"] == true) _load();
  }

  Future<void> _share(Map<String, dynamic> d) async {
    final r = await HelpApi.reportLink("damage", damageId: d["id"]);
    if (!mounted) return;
    if (r["success"] != true) return showSnack(context, apiMessage(r));
    final url = "${r["url"]}";
    await ShareHelper.openLink(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("Crop damage reports", "බෝග හානි වාර්තා", "பயிர் சேத அறிக்கைகள்"))),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add_a_photo_rounded), label: Text(tr("New report", "නව වාර්තාව", "புதிய அறிக்கை"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
          InfoBanner(icon: Icons.fact_check_rounded, text: tr("Photos and details kept safely. Share the report page with an insurer or your officer. The loss figure is your own estimate.", "ඡායාරූප හා විස්තර ආරක්ෂිතව තබයි. වාර්තා පිටුව රක්ෂණ ආයතනයක් හෝ නිලධාරියෙක් සමඟ බෙදාගන්න. අලාභ සංඛ්‍යාව ඔබේම ඇස්තමේන්තුවකි.", "படங்களும் விவரங்களும் பாதுகாப்பாக இருக்கும். அறிக்கைப் பக்கத்தை காப்பீட்டாளர் அல்லது அலுவலருடன் பகிரவும். இழப்பு எண் உங்கள் மதிப்பீடு.")),
          const SizedBox(height: 12),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
          if (!_loading && _error == null && _items.isEmpty) emptyState(Icons.storm_rounded, tr("No reports", "වාර්තා නැත", "அறிக்கைகள் இல்லை"), tr("If a storm, flood or pests hit your crop, record it here.", "කුණාටුවක්, ගංවතුරක් හෝ පළිබෝධ බෝගයට වැදුනොත් මෙහි වාර්තා කරන්න.", "புயல், வெள்ளம், பூச்சி தாக்கினால் இங்கே பதிவு செய்யவும்.")),
          ..._items.map((d) => SoftCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("${cropLabel("${d["cropType"]}")} • ${_cause("${d["cause"]}")}", style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text("${"${d["happenedOn"]}".substring(0, 10)} • ${d["acresAffected"]} ac • ${lkr(d["estimatedLossLkr"] as num)} • ${(d["photoIds"] as List).length} ${tr("photos", "ඡායාරූප", "படங்கள்")}", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(onPressed: () => _share(d), icon: const Icon(Icons.description_rounded), label: Text(tr("Open printable report", "මුද්‍රණය කළ හැකි වාර්තාව", "அச்சிடக்கூடிய அறிக்கை"))),
                ]),
              )),
        ]),
      ),
    );
  }
}
