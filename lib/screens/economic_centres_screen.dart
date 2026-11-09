import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/help_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/smooth_route.dart';
import '../widgets/ui_kit.dart';

List<Map<String, dynamic>> _asMaps(dynamic v) =>
    (v is List ? v : const []).map((e) => Map<String, dynamic>.from(e as Map)).toList();

/// Horizontal strip shown on the Logistics tab: every economic centre, with the
/// "Special" one (Manikkumbura) first and highlighted. Tap one to see its
/// contact details and its stores.
class EconomicCentresStrip extends StatefulWidget {
  const EconomicCentresStrip({super.key});

  @override
  State<EconomicCentresStrip> createState() => _EconomicCentresStripState();
}

class _EconomicCentresStripState extends State<EconomicCentresStrip> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await HelpApi.economicCentres();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r["success"] == true) _items = _asMaps(r["data"]);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
          child: Row(children: [
            const Icon(Icons.storefront_rounded, size: 18, color: AppColors.forest),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr("Economic centres", "ආර්ථික මධ්‍යස්ථාන", "பொருளாதார மையங்கள்"),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
            if (_items.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.push(context, SmoothRoute(page: EconomicCentresScreen(initial: _items))),
                child: Text(tr("See all", "සියල්ල", "அனைத்தும்")),
              ),
          ]),
        ),
        SizedBox(
          height: 120,
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => _CentreCard(centre: _items[i], width: 230),
                ),
        ),
      ],
    );
  }
}

class _CentreCard extends StatelessWidget {
  final Map<String, dynamic> centre;
  final double? width;
  const _CentreCard({required this.centre, this.width});

  @override
  Widget build(BuildContext context) {
    final featured = centre["featured"] == true;
    final phone = "${centre["phone"] ?? ""}";
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context, SmoothRoute(page: EconomicCentreScreen(centre: centre))),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: featured ? tintOf(context, AppColors.gold) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: featured ? AppColors.gold : Theme.of(context).dividerColor, width: featured ? 1.6 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (featured)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                    const SizedBox(width: 4),
                    Text(tr("Special", "විශේෂ", "சிறப்பு"), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gold)),
                  ]),
                ),
              Text("${centre["name"]}", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              const Spacer(),
              Row(children: [
                Expanded(
                  child: Text(
                    "${centre["district"]} · ${centre["stallCount"]} ${tr("stores", "වෙළඳසැල්", "கடைகள்")}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: mutedOf(context)),
                  ),
                ),
                if (phone.isNotEmpty) const Icon(Icons.call_rounded, size: 15, color: AppColors.forest),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full list of economic centres.
class EconomicCentresScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initial;
  const EconomicCentresScreen({super.key, this.initial});

  @override
  State<EconomicCentresScreen> createState() => _EconomicCentresScreenState();
}

class _EconomicCentresScreenState extends State<EconomicCentresScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null && widget.initial!.isNotEmpty) {
      _items = widget.initial!;
      _loading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await HelpApi.economicCentres();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r["success"] == true) {
        _items = _asMaps(r["data"]);
      } else {
        _error = apiMessage(r);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("Economic centres", "ආර්ථික මධ්‍යස්ථාන", "பொருளாதார மையங்கள்"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
          children: [
            if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
            if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
            ..._items.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SizedBox(height: 108, child: _CentreCard(centre: c)),
                )),
          ],
        ),
      ),
    );
  }
}

/// One economic centre: contact details (with a call button) and the stores inside it.
class EconomicCentreScreen extends StatefulWidget {
  final Map<String, dynamic> centre;
  const EconomicCentreScreen({super.key, required this.centre});

  @override
  State<EconomicCentreScreen> createState() => _EconomicCentreScreenState();
}

class _EconomicCentreScreenState extends State<EconomicCentreScreen> {
  String _q = "";

  List<Map<String, dynamic>> get _stalls {
    final all = _asMaps(widget.centre["stalls"]);
    final q = _q.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((s) {
      final deals = (s["deals"] is List ? s["deals"] as List : const []).join(" ").toLowerCase();
      return "${s["number"]}".contains(q) || "${s["name"]}".toLowerCase().contains(q) || deals.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.centre;
    final phone = "${c["phone"] ?? ""}";
    final address = "${c["address"] ?? ""}";
    final hours = "${c["hours"] ?? ""}";
    final featured = c["featured"] == true;
    final stalls = _stalls;
    return Scaffold(
      appBar: AppBar(title: Text("${c["name"]}", style: const TextStyle(fontSize: 16))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: featured ? tintOf(context, AppColors.gold) : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: featured ? AppColors.gold : Theme.of(context).dividerColor, width: featured ? 1.6 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (featured)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: StatusPill(label: tr("Special economic centre", "විශේෂ ආර්ථික මධ්‍යස්ථානය", "சிறப்புப் பொருளாதார மையம்"), color: AppColors.gold, icon: Icons.star_rounded),
                  ),
                Text("${c["name"]}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.place_rounded, size: 16, color: mutedOf(context)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(address.isEmpty ? "${c["district"]}" : "$address · ${c["district"]}", style: const TextStyle(fontSize: 13))),
                ]),
                if (hours.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(children: [
                      Icon(Icons.schedule_rounded, size: 16, color: mutedOf(context)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(hours, style: const TextStyle(fontSize: 13))),
                    ]),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(children: [
                    Icon(Icons.store_rounded, size: 16, color: mutedOf(context)),
                    const SizedBox(width: 6),
                    Text("${c["stallCount"]} ${tr("stores", "වෙළඳසැල්", "கடைகள்")}", style: const TextStyle(fontSize: 13)),
                  ]),
                ),
                if (phone.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => callPhone(phone),
                        icon: const Icon(Icons.call_rounded, size: 18),
                        label: Text("${tr("Call", "අමතන්න", "அழைக்க")} $phone"),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: tr("Search store number, name or vegetable", "වෙළඳසැල් අංකය, නම හෝ එළවළු සොයන්න", "கடை எண், பெயர் அல்லது காய்கறி தேடுக"),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          Text("${stalls.length} ${tr("stores", "වෙළඳසැල්", "கடைகள்")}", style: TextStyle(fontSize: 12, color: mutedOf(context))),
          const SizedBox(height: 6),
          if (stalls.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(tr("No store matches your search.", "ගැලපෙන වෙළඳසැලක් නැත.", "பொருந்தும் கடை இல்லை."), style: TextStyle(color: mutedOf(context)))),
            ),
          ...stalls.map((s) => _StallTile(stall: s)),
          const SizedBox(height: 10),
          Text(
            tr("Store lists are demo data. Call the centre office to confirm a store before you travel.", "වෙළඳසැල් ලැයිස්තු නියැදි දත්ත වේ. ගමන් කිරීමට පෙර තහවුරු කරගන්න.", "கடை பட்டியல்கள் மாதிரி தரவு. பயணத்திற்கு முன் உறுதிப்படுத்தவும்."),
            style: TextStyle(fontSize: 11, color: mutedOf(context)),
          ),
        ],
      ),
    );
  }
}

class _StallTile extends StatelessWidget {
  final Map<String, dynamic> stall;
  const _StallTile({required this.stall});

  @override
  Widget build(BuildContext context) {
    final featured = stall["featured"] == true;
    final phone = "${stall["phone"] ?? ""}";
    final note = "${stall["note"] ?? ""}";
    final deals = (stall["deals"] is List ? stall["deals"] as List : const []).join(", ");
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: featured ? tintOf(context, AppColors.gold) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: featured ? AppColors.gold : Theme.of(context).dividerColor, width: featured ? 1.6 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: featured ? AppColors.gold : AppColors.forest, borderRadius: BorderRadius.circular(10)),
            child: Column(children: [
              Text(tr("Store", "සැල", "கடை"), style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
              Text("${stall["number"]}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${stall["name"]}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                if (deals.isNotEmpty) Text(deals, style: TextStyle(fontSize: 12, color: mutedOf(context))),
                if (note.isNotEmpty) Text(note, style: TextStyle(fontSize: 11.5, color: mutedOf(context))),
                if (phone.isNotEmpty) Text(phone, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            CircleAvatar(
              backgroundColor: AppColors.forest,
              child: IconButton(
                onPressed: () => callPhone(phone),
                tooltip: tr("Call", "අමතන්න", "அழைக்க"),
                icon: const Icon(Icons.call_rounded, size: 20, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
