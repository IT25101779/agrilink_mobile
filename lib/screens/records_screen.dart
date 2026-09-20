import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import '../services/share_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/ui_kit.dart';

/// My harvests (kg per acre, compared with neighbours) and the fertilizer / seed support I received.
class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  List<Map<String, dynamic>> _yields = [], _subs = [];
  double _subTotal = 0;
  bool _loading = true;
  bool _offline = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final y = await HelpApi.yields();
    final s = await HelpApi.subsidies();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _offline = y["cached"] == true || s["cached"] == true;
      _error = y["success"] == true ? null : apiMessage(y);
      if (y["success"] == true) _yields = (y["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (s["success"] == true) {
        _subs = (s["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _subTotal = numOf(s["totalValueLkr"]);
      }
    });
  }

  double? _num(String t) => double.tryParse(t.trim().replaceAll(",", ""));

  Future<void> _addYield() async {
    String crop = allCropNames().first, season = "maha";
    final year = TextEditingController(text: "${DateTime.now().year}");
    final acres = TextEditingController(), kg = TextEditingController();
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr("Add a harvest", "අස්වැන්නක් එක් කරන්න", "அறுவடை சேர்க்கவும்"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(value: crop, decoration: InputDecoration(labelText: tr("Crop", "බෝගය", "பயிர்"), border: const OutlineInputBorder()), items: allCropNames().map((c) => DropdownMenuItem(value: c, child: Text(cropLabel(c)))).toList(), onChanged: (v) => setS(() => crop = v ?? crop)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                for (final s in ["yala", "maha", "other"]) ChoiceChip(label: Text(s == "yala" ? tr("Yala", "යල", "சிறுபோகம்") : s == "maha" ? tr("Maha", "මහ", "பெரும்போகம்") : tr("Other", "වෙනත්", "பிற")), selected: season == s, onSelected: (_) => setS(() => season = s)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: year, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr("Year", "වර්ෂය", "ஆண்டு"), border: const OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: acres, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr("Acres", "අක්කර", "ஏக்கர்"), border: const OutlineInputBorder()))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: kg, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: tr("Harvest kg", "අස්වැන්න කි.ග්‍රෑ", "அறுவடை கிலோ"), border: const OutlineInputBorder()))),
              ]),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr("Save", "සුරකින්න", "சேமி")))),
            ]),
          ),
        ),
      ),
    );
    if (go != true) return;
    final r = await HelpApi.addYield({"cropType": crop, "season": season, "year": int.tryParse(year.text.trim()) ?? DateTime.now().year, "acres": _num(acres.text) ?? 0, "harvestKg": _num(kg.text) ?? 0});
    if (!mounted) return;
    showSnack(context, r["success"] == true ? (r["queued"] == true ? apiMessage(r) : tr("Saved.", "සුරකින ලදි.", "சேமிக்கப்பட்டது.")) : apiMessage(r));
    if (r["success"] == true) _load();
  }

  Future<void> _addSubsidy() async {
    String kind = "fertilizer";
    final item = TextEditingController(), value = TextEditingController();
    DateTime received = DateTime.now();
    DateTime? next;
    final go = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr("Add support received", "ලැබුණු සහනාධාරය එක් කරන්න", "பெற்ற உதவியைச் சேர்க்கவும்"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, children: [
                for (final k in ["fertilizer", "seed", "cash", "equipment", "other"]) ChoiceChip(label: Text(_kind(k)), selected: kind == k, onSelected: (_) => setS(() => kind = k)),
              ]),
              const SizedBox(height: 8),
              TextField(controller: item, decoration: InputDecoration(labelText: tr("What (e.g. Urea 50 kg)", "කුමක්ද (උදා: යූරියා 50 කි.ග්‍රෑ)", "என்ன (எ.கா. யூரியா 50 கிலோ)"), border: const OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: value, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr("Value in LKR (optional)", "වටිනාකම රු. (විකල්ප)", "மதிப்பு ரூ. (விருப்பம்)"), border: const OutlineInputBorder())),
              const SizedBox(height: 8),
              ListTile(contentPadding: EdgeInsets.zero, title: Text("${tr("Received on", "ලැබුණු දිනය", "பெற்ற நாள்")}: ${received.toIso8601String().substring(0, 10)}"), trailing: const Icon(Icons.calendar_today_rounded), onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: received, firstDate: DateTime.now().subtract(const Duration(days: 1800)), lastDate: DateTime.now());
                if (d != null) setS(() => received = d);
              }),
              ListTile(contentPadding: EdgeInsets.zero, title: Text("${tr("Next one due (optional)", "ඊළඟ එක (විකල්ප)", "அடுத்தது (விருப்பம்)")}: ${next == null ? "-" : next!.toIso8601String().substring(0, 10)}"), trailing: const Icon(Icons.notifications_active_rounded), onTap: () async {
                final d = await showDatePicker(context: ctx, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: received, lastDate: DateTime.now().add(const Duration(days: 700)));
                if (d != null) setS(() => next = d);
              }),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr("Save", "සුරකින්න", "சேமி")))),
            ]),
          ),
        ),
      ),
    );
    if (go != true) return;
    final r = await HelpApi.addSubsidy({"kind": kind, "item": item.text.trim(), "valueLkr": _num(value.text) ?? 0, "receivedOn": received.toIso8601String(), if (next != null) "nextDueOn": next!.toIso8601String()});
    if (!mounted) return;
    showSnack(context, r["success"] == true ? tr("Saved. We'll remind you before the next one.", "සුරකින ලදි. ඊළඟ එකට පෙර මතක් කරමු.", "சேமிக்கப்பட்டது. அடுத்ததற்கு முன் நினைவூட்டுவோம்.") : apiMessage(r));
    if (r["success"] == true) _load();
  }

  String _kind(String k) {
    switch (k) {
      case "fertilizer":
        return tr("Fertilizer", "පොහොර", "உரம்");
      case "seed":
        return tr("Seed", "බීජ", "விதை");
      case "cash":
        return tr("Cash", "මුදල්", "பணம்");
      case "equipment":
        return tr("Equipment", "උපකරණ", "உபகரணம்");
      default:
        return tr("Other", "වෙනත්", "பிற");
    }
  }

  Future<void> _lenderReport() async {
    final r = await HelpApi.reportLink("loan");
    if (!mounted) return;
    if (r["success"] != true) return showSnack(context, apiMessage(r));
    final url = "${r["url"]}";
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tr("Finance summary for a lender", "ණය දෙන්නෙකු සඳහා මූල්‍ය සාරාංශය", "கடன் வழங்குநருக்கான நிதிச் சுருக்கம்"), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 6),
            Text(tr("A web page with your ledger totals, harvests and AgriLink record. The link works for 48 hours. The figures you entered are not audited, and the page says so.", "ඔබේ ගිණුම් එකතු, අස්වැන්න සහ AgriLink වාර්තාව සහිත පිටුවකි. සබැඳිය පැය 48ක් ක්‍රියා කරයි. ඔබ ඇතුළත් කළ සංඛ්‍යා විගණනය කර නැති බව පිටුවේ සඳහන්.", "உங்கள் கணக்கு மொத்தம், அறுவடை, AgriLink பதிவு கொண்ட வலைப்பக்கம். இணைப்பு 48 மணி நேரம் செயல்படும். நீங்கள் உள்ளிட்ட எண்கள் தணிக்கை செய்யப்படவில்லை என்று பக்கம் கூறுகிறது."), style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => ShareHelper.openLink(url), icon: const Icon(Icons.open_in_browser_rounded), label: Text(tr("Open / print", "විවෘත / මුද්‍රණය", "திற / அச்சிடு")))),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => ShareHelper.whatsapp("${tr("My farm finance summary", "මගේ ගොවිපල මූල්‍ය සාරාංශය", "எனது பண்ணை நிதிச் சுருக்கம்")}: $url"), icon: const Icon(Icons.share_rounded), label: const Text("WhatsApp"))),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr("My farm records", "මගේ ගොවිපල වාර්තා", "எனது பண்ணை பதிவுகள்")),
          actions: [IconButton(tooltip: tr("Report for lender", "ණය වාර්තාව", "கடன் அறிக்கை"), icon: const Icon(Icons.description_rounded), onPressed: _lenderReport)],
          bottom: TabBar(tabs: [Tab(text: tr("Harvests", "අස්වැන්න", "அறுவடை")), Tab(text: tr("Support received", "ලැබුණු සහනාධාර", "பெற்ற உதவி"))]),
        ),
        floatingActionButton: Builder(builder: (ctx) => FloatingActionButton(onPressed: () => DefaultTabController.of(ctx).index == 0 ? _addYield() : _addSubsidy(), child: const Icon(Icons.add_rounded))),
        body: TabBarView(children: [
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
              if (_offline) InfoBanner(icon: Icons.cloud_off_rounded, text: tr("Showing saved data (no internet).", "සුරකින ලද දත්ත පෙන්වයි (අන්තර්ජාලය නැත).", "சேமித்த தரவு (இணையம் இல்லை)."), color: AppColors.inkMuted),
              if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
              if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
              if (!_loading && _error == null && _yields.isEmpty) emptyState(Icons.agriculture_rounded, tr("No harvests yet", "අස්වැන්න වාර්තා නැත", "அறுவடை பதிவுகள் இல்லை"), tr("Add one to see your kg per acre.", "අක්කරයකට කි.ග්‍රෑ බැලීමට එකක් එක් කරන්න.", "ஏக்கருக்கு கிலோ காண ஒன்றைச் சேர்க்கவும்.")),
              ..._yields.map((y) => SoftCard(
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("${cropLabel("${y["cropType"]}")} • ${y["season"]} ${y["year"]}", style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text("${y["acres"]} ac • ${groupedNumber(y["harvestKg"] as num)} kg", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                        Text(y["districtKgPerAcre"] == null ? tr("District average appears when 3+ neighbours share theirs.", "අසල්වැසි 3ක්+ බෙදාගත් විට දිස්ත්‍රික්ක සාමාන්‍යය පෙනේ.", "3+ அண்டையர் பகிரும்போது மாவட்ட சராசரி தெரியும்.") : "${tr("District average", "දිස්ත්‍රික්ක සාමාන්‍යය", "மாவட்ட சராசரி")}: ${groupedNumber(y["districtKgPerAcre"] as num)} kg/ac", style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
                      ])),
                      Column(children: [Text("${groupedNumber(y["kgPerAcre"] as num)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.forest)), const Text("kg/acre", style: TextStyle(fontSize: 10))]),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () async {
                        await HelpApi.deleteYield(y["id"]);
                        _load();
                      }),
                    ]),
                  )),
            ]),
          ),
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
              if (_subs.isNotEmpty) InfoBanner(icon: Icons.volunteer_activism_rounded, text: "${tr("Total support recorded", "වාර්තා කළ මුළු සහනාධාරය", "பதிவான மொத்த உதவி")}: ${lkr(_subTotal)}"),
              if (!_loading && _subs.isEmpty) emptyState(Icons.inventory_2_rounded, tr("Nothing recorded", "කිසිවක් වාර්තා කර නැත", "எதுவும் பதிவாகவில்லை"), tr("Record fertilizer or seed you received, and we'll remind you when the next is due.", "ලැබුණු පොහොර/බීජ වාර්තා කරන්න; ඊළඟ එක ලඟා වන විට මතක් කරමු.", "பெற்ற உரம்/விதையைப் பதிவு செய்யுங்கள்; அடுத்தது வரும்போது நினைவூட்டுவோம்.")),
              ..._subs.map((s) => SoftCard(
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("${_kind("${s["kind"]}")}${"${s["item"]}".isEmpty ? "" : " • ${s["item"]}"}", style: const TextStyle(fontWeight: FontWeight.w800)),
                        Text("${tr("Received", "ලැබුණි", "பெற்றது")}: ${"${s["receivedOn"]}".substring(0, 10)}${s["nextDueOn"] == null ? "" : "  •  ${tr("Next", "ඊළඟ", "அடுத்து")}: ${"${s["nextDueOn"]}".substring(0, 10)}"}", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                        if ((s["valueLkr"] as num) > 0) Text(lkr(s["valueLkr"] as num), style: const TextStyle(fontSize: 12)),
                      ])),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded), onPressed: () async {
                        await HelpApi.deleteSubsidy(s["id"]);
                        _load();
                      }),
                    ]),
                  )),
            ]),
          ),
        ]),
      ),
    );
  }
}
