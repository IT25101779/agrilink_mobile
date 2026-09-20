import 'package:flutter/material.dart';
import '../localization/chat_labels.dart';
import '../localization/tr.dart';
import '../services/farm_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/ui_kit.dart';

/// For drivers: post an empty return journey, then confirm or decline the farmers who ask for space.
class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen> {
  List<Map<String, dynamic>> _trips = [];
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
    final result = await FarmApi.myTrips();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result["success"] == true) {
        _trips = (result["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _error = apiMessage(result);
      }
    });
  }

  Future<void> _post() async {
    String hub = "Dambulla";
    String district = "Kandy";
    final now = DateTime.now();
    DateTime when = DateTime(now.year, now.month, now.day + 1, 6, 0);
    final kg = TextEditingController();
    final price = TextEditingController();
    final regular = TextEditingController();
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
              Text(tr("Post an empty return trip", "හිස් ආපසු ගමනක් පළ කරන්න", "காலி திரும்பும் பயணத்தைப் பதிவிடு"), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(value: hub, isExpanded: true, decoration: InputDecoration(labelText: tr("Starting from", "ආරම්භය", "தொடங்குமிடம்")), items: kTruckHubs.map((h) => DropdownMenuItem(value: h, child: Text(hubName(h)))).toList(), onChanged: (v) => setSheet(() => hub = v ?? hub)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(value: district, isExpanded: true, decoration: InputDecoration(labelText: tr("Driving back to", "ආපසු යන්නේ", "திரும்பிச் செல்வது")), items: kChatDistricts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => setSheet(() => district = v ?? district)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.schedule_rounded),
                label: Text(whenText(when.toIso8601String())),
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: when, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 14)));
                  if (d == null) return;
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(when));
                  if (t == null) return;
                  setSheet(() => when = DateTime(d.year, d.month, d.day, t.hour, t.minute));
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: kg, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr("Empty space (kg)", "හිස් ඉඩ (kg)", "காலி இடம் (கி.கி)"))),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: price, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr("Price LKR/kg", "මිල රු/kg", "விலை ரூ/கி.கி")))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: regular, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr("Usual price", "සුපුරුදු මිල", "வழக்கமான விலை")))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: note, maxLength: 200, decoration: InputDecoration(labelText: tr("Note (optional)", "සටහන (විකල්ප)", "குறிப்பு (விருப்பம்)"))),
              if (error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(error!, style: const TextStyle(color: AppColors.danger))),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final result = await FarmApi.createTrip({
                      "fromHub": hub,
                      "toDistrict": district,
                      "departAt": when.toUtc().toIso8601String(),
                      "availableKg": double.tryParse(kg.text.trim()) ?? 0,
                      "pricePerKg": double.tryParse(price.text.trim()) ?? 0,
                      if (regular.text.trim().isNotEmpty) "regularPricePerKg": double.tryParse(regular.text.trim()) ?? 0,
                      "note": note.text.trim(),
                    });
                    if (result["success"] == true) {
                      if (context.mounted) Navigator.pop(context, true);
                    } else {
                      setSheet(() => error = apiMessage(result));
                    }
                  },
                  child: Text(tr("Post trip", "ගමන පළ කරන්න", "பயணத்தைப் பதிவிடு")),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    if (ok == true) {
      if (mounted) showSnack(context, tr("Trip posted. Farmers can now book space.", "ගමන පළ කළා. ගොවීන්ට දැන් ඉඩ වෙන්කළ හැක.", "பயணம் பதிவிடப்பட்டது. விவசாயிகள் இடம் பதிவு செய்யலாம்."));
      _load();
    }
  }

  Future<void> _answer(Map<String, dynamic> trip, Map<String, dynamic> b, String action) async {
    final result = await FarmApi.updateBooking(trip["id"], b["id"], action);
    if (!mounted) return;
    if (result["success"] != true) showSnack(context, apiMessage(result));
    _load();
  }

  Future<void> _cancelTrip(Map<String, dynamic> trip) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr("Cancel this trip?", "මෙම ගමන අවලංගු කරන්නද?", "இந்தப் பயணத்தை ரத்து செய்யவா?")),
        content: Text(tr("Farmers who booked space will be told.", "ඉඩ වෙන්කළ ගොවීන්ට දැනුම් දෙනු ලැබේ.", "இடம் பதிவு செய்த விவசாயிகளுக்குத் தெரிவிக்கப்படும்.")),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr("No", "නැත", "வேண்டாம்"))), TextButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Yes, cancel", "ඔව්, අවලංගු කරන්න", "ஆம், ரத்து செய்")))],
      ),
    );
    if (sure != true) return;
    await FarmApi.cancelTrip(trip["id"]);
    _load();
  }

  String _statusText(String s) => s == "requested" ? tr("Waiting for you", "ඔබ එනතුරු", "உங்களுக்காகக் காத்திருக்கிறது") : s == "confirmed" ? tr("Confirmed", "තහවුරු කළා", "உறுதிசெய்யப்பட்டது") : s == "rejected" ? tr("Declined", "ප්‍රතික්ෂේප කළා", "நிராகரிக்கப்பட்டது") : tr("Cancelled", "අවලංගුයි", "ரத்துசெய்யப்பட்டது");

  Widget _card(Map<String, dynamic> t) {
    final bookings = ((t["bookings"] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final open = t["status"] == "open";
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text("${hubName("${t["fromHub"]}")} → ${t["toDistrict"]}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          StatusPill(label: open ? tr("Open", "විවෘත", "திறந்தது") : tr("Cancelled", "අවලංගුයි", "ரத்துசெய்யப்பட்டது"), color: open ? AppColors.forest : Colors.grey),
        ]),
        Text("${whenText("${t["departAt"]}")} · LKR ${priceText(numOf(t["pricePerKg"]))}/kg · ${t["remainingKg"]}/${t["availableKg"]} kg ${tr("free", "නිදහස්", "காலி")}", style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
        ...bookings.map((b) {
          final farmer = (b["farmer"] as Map?) ?? {};
          return Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${farmer["name"] ?? tr("Farmer", "ගොවියා", "விவசாயி")} · ${b["weightKg"]} kg ${b["cropType"] != null && "${b["cropType"]}".isNotEmpty ? "· ${cropLabel("${b["cropType"]}")}" : ""}", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(_statusText("${b["status"]}"), style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
              if (b["status"] == "confirmed" && farmer["phone"] != null) TextButton.icon(onPressed: () => callPhone("${farmer["phone"]}"), icon: const Icon(Icons.call_rounded, size: 16), label: Text("${farmer["phone"]}")),
              if (b["status"] == "requested" && open) Row(children: [
                OutlinedButton(onPressed: () => _answer(t, b, "reject"), child: Text(tr("Decline", "ප්‍රතික්ෂේප", "நிராகரி"))),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: () => _answer(t, b, "confirm"), child: Text(tr("Confirm", "තහවුරු කරන්න", "உறுதிசெய்"))),
              ]),
            ]),
          );
        }),
        if (open) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => _cancelTrip(t), child: Text(tr("Cancel trip", "ගමන අවලංගු කරන්න", "பயணத்தை ரத்து செய்"), style: const TextStyle(color: AppColors.danger)))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("My return trips", "මගේ ආපසු ගමන්", "என் திரும்பும் பயணங்கள்"))),
      floatingActionButton: FloatingActionButton.extended(onPressed: _post, icon: const Icon(Icons.add_road_rounded), label: Text(tr("Post trip", "ගමන පළ කරන්න", "பயணத்தைப் பதிவிடு"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 100), children: [
          InfoBanner(icon: Icons.lightbulb_outline_rounded, text: tr("Driving back empty? Post the trip. Farmers on your route book the empty space and you earn instead of driving for free.", "හිස්ව ආපසු යනවාද? ගමන පළ කරන්න. ඔබේ මාර්ගයේ ගොවීන් හිස් ඉඩ වෙන්කරන අතර ඔබ නොමිලේ ධාවනය කරනවා වෙනුවට ආදායම් ලබයි.", "காலியாகத் திரும்புகிறீர்களா? பயணத்தைப் பதிவிடுங்கள். உங்கள் வழியிலுள்ள விவசாயிகள் இடத்தைப் பதிவு செய்வார்கள்; இலவசமாக ஓட்டுவதற்குப் பதிலாக வருமானம் பெறுவீர்கள்."), color: AppColors.forest),
          const SizedBox(height: 12),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
          if (!_loading && _error == null && _trips.isEmpty) emptyState(Icons.add_road_rounded, tr("No trips yet", "තවම ගමන් නැත", "இன்னும் பயணங்கள் இல்லை"), tr("Tap “Post trip” to offer your empty return journey.", "ඔබේ හිස් ආපසු ගමන පිරිනැමීමට “ගමන පළ කරන්න” ඔබන්න.", "உங்கள் காலி திரும்பும் பயணத்தை வழங்க “பயணத்தைப் பதிவிடு” அழுத்தவும்.")),
          ..._trips.map(_card),
        ]),
      ),
    );
  }
}
