import 'package:flutter/material.dart';
import '../localization/chat_labels.dart';
import '../localization/tr.dart';
import '../services/auth_service.dart';
import '../services/farm_api.dart';
import '../theme/app_theme.dart';
import '../widgets/delivery_check_sheet.dart';
import '../widgets/farm_common.dart';
import '../widgets/trust_badge.dart';
import '../widgets/ui_kit.dart';

/// Trucks that are driving back EMPTY offer cheap space to your area. Book a place, the driver confirms.
class ReturnTripsScreen extends StatefulWidget {
  const ReturnTripsScreen({super.key});

  @override
  State<ReturnTripsScreen> createState() => _ReturnTripsScreenState();
}

class _ReturnTripsScreenState extends State<ReturnTripsScreen> {
  String? _district;
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _mine = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AuthService.getDistrict().then((d) {
      if (mounted && d != null && kChatDistricts.contains(d)) _district = d;
      _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final results = await Future.wait([FarmApi.returnTrips(district: _district), FarmApi.myTrips()]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (results[0]["success"] == true) {
        _trips = (results[0]["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _error = apiMessage(results[0]);
      }
      if (results[1]["success"] == true) {
        _mine = (results[1]["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    });
  }

  Future<void> _book(Map<String, dynamic> trip) async {
    final kg = TextEditingController();
    String crop = "Tomato";
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${hubName("${trip["fromHub"]}")} → ${trip["toDistrict"]}", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text("${tr("Space left", "ඉතිරි ඉඩ", "மீதமுள்ள இடம்")}: ${trip["remainingKg"]} kg · LKR ${priceText(numOf(trip["pricePerKg"]))}/kg", style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
            const SizedBox(height: 14),
            TextField(controller: kg, autofocus: true, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr("Weight (kg)", "බර (kg)", "எடை (கி.கி)"))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: crop,
              isExpanded: true,
              decoration: InputDecoration(labelText: tr("Crop", "බෝගය", "பயிர்")),
              items: allCropNames().map((c) => DropdownMenuItem(value: c, child: Text(cropLabel(c)))).toList(),
              onChanged: (v) => setSheet(() => crop = v ?? crop),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Request space", "ඉඩ ඉල්ලන්න", "இடம் கோரு")))),
          ]),
        ),
      ),
    );
    if (ok != true) return;
    final weight = int.tryParse(kg.text.trim()) ?? 0;
    final result = await FarmApi.bookTrip(trip["id"], weight, crop);
    if (!mounted) return;
    showSnack(context, result["success"] == true ? tr("Requested. The driver will confirm soon.", "ඉල්ලා ඇත. රියදුරු ඉක්මනින් තහවුරු කරයි.", "கோரப்பட்டது. ஓட்டுநர் விரைவில் உறுதிப்படுத்துவார்.") : apiMessage(result));
    if (result["success"] == true) _load();
  }

  Future<void> _cancelBooking(Map<String, dynamic> trip, Map<String, dynamic> booking) async {
    final result = await FarmApi.updateBooking(trip["id"], booking["id"], "cancel");
    if (!mounted) return;
    showSnack(context, result["success"] == true ? tr("Booking cancelled.", "වෙන්කිරීම අවලංගු කළා.", "பதிவு ரத்து செய்யப்பட்டது.") : apiMessage(result));
    _load();
  }

  String _bookingLabel(String s) {
    switch (s) {
      case "requested":
        return tr("Waiting for driver", "රියදුරු තහවුරු කරන තෙක්", "ஓட்டுநர் உறுதிப்படுத்த காத்திருக்கிறது");
      case "confirmed":
        return tr("Confirmed", "තහවුරු කළා", "உறுதிசெய்யப்பட்டது");
      case "rejected":
        return tr("Declined", "ප්‍රතික්ෂේප කළා", "நிராகரிக்கப்பட்டது");
      default:
        return tr("Cancelled", "අවලංගුයි", "ரத்துசெய்யப்பட்டது");
    }
  }

  Widget _tripCard(Map<String, dynamic> t) {
    final saving = t["savingPercent"];
    final driver = Map<String, dynamic>.from(t["driver"] as Map);
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text("${hubName("${t["fromHub"]}")} → ${t["toDistrict"]}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          if (saving != null && (saving as num) > 0) StatusPill(label: tr("Save $saving%", "$saving% ඉතිරි", "$saving% சேமிப்பு"), color: AppColors.forest),
        ]),
        const SizedBox(height: 6),
        Text("${tr("Departs", "පිටත් වේ", "புறப்பாடு")}: ${whenText("${t["departAt"]}")}", style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text("LKR ${priceText(numOf(t["pricePerKg"]))}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.forest)),
          const Text(" /kg", style: TextStyle(fontSize: 12)),
          if (t["regularPricePerKg"] != null) Text("   ${priceText(numOf(t["regularPricePerKg"]))}", style: const TextStyle(fontSize: 13, color: Colors.grey, decoration: TextDecoration.lineThrough)),
          const Spacer(),
          Text("${t["remainingKg"]} kg ${tr("left", "ඉතිරි", "மீதம்")}", style: const TextStyle(fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 8),
        Row(children: [Text("${driver["firstName"]}  ", style: const TextStyle(fontWeight: FontWeight.w700)), TrustBadge(trust: driver["trust"] as Map?, compact: true)]),
        if ("${t["note"]}".isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text("${t["note"]}", style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted))),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _book(t), child: Text(tr("Book space", "ඉඩ වෙන්කරන්න", "இடத்தைப் பதிவுசெய்")))),
      ]),
    );
  }

  Widget _mineCard(Map<String, dynamic> t) {
    final driver = Map<String, dynamic>.from(t["driver"] as Map);
    final bookings = ((t["myBookings"] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("${hubName("${t["fromHub"]}")} → ${t["toDistrict"]}", style: const TextStyle(fontWeight: FontWeight.w800)),
        Text(whenText("${t["departAt"]}"), style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
        ...bookings.map((b) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(children: [
                Expanded(child: Text("${b["weightKg"]} kg · ${_bookingLabel("${b["status"]}")}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                if (b["status"] == "confirmed" && driver["phone"] != null) IconButton(onPressed: () => callPhone("${driver["phone"]}"), icon: const Icon(Icons.call_rounded, color: AppColors.forest)),
                if (["requested", "confirmed"].contains(b["status"])) TextButton(onPressed: () => _cancelBooking(t, b), child: Text(tr("Cancel", "අවලංගු", "ரத்து"))),
              ]),
            )),
        if (bookings.any((b) => b["status"] == "confirmed") && t["vehicleRegistrationNo"] != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text("${tr("Vehicle", "වාහනය", "வாகனம்")}: ${t["vehicleRegistrationNo"]}", style: const TextStyle(fontSize: 12.5))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeMine = _mine.where((t) => ((t["myBookings"] as List?) ?? []).any((b) => ["requested", "confirmed"].contains((b as Map)["status"]))).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("Return-load deals", "ආපසු ගමන් දීමනා", "திரும்பும் லாரி சலுகைகள்")),
        actions: [IconButton(tooltip: tr("Delivery freshness", "බෙදාහැරීමේ නැවුම්බව", "விநியோகப் புத்துணர்ச்சி"), icon: const Icon(Icons.ac_unit_rounded), onPressed: () => showDeliveryCheckSheet(context))],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
          Text(tr("Trucks driving back empty offer cheap space to your area.", "හිස්ව ආපසු යන ට්‍රක් රථ ඔබේ ප්‍රදේශයට ලාභ ඉඩ ලබා දේ.", "காலியாகத் திரும்பும் லாரிகள் உங்கள் பகுதிக்கு மலிவான இடம் தருகின்றன."), style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _district,
            isExpanded: true,
            decoration: InputDecoration(labelText: tr("Going to district", "යන දිස්ත්‍රික්කය", "செல்லும் மாவட்டம்")),
            items: [DropdownMenuItem<String?>(value: null, child: Text(tr("Any district", "ඕනෑම දිස්ත්‍රික්කයක්", "எந்த மாவட்டமும்"))), ...kChatDistricts.map((d) => DropdownMenuItem<String?>(value: d, child: Text(d)))],
            onChanged: (v) {
              setState(() => _district = v);
              _load();
            },
          ),
          const SizedBox(height: 14),
          if (activeMine.isNotEmpty) ...[
            SectionHeader(title: tr("My bookings", "මගේ වෙන්කිරීම්", "என் பதிவுகள்")),
            ...activeMine.map(_mineCard),
            const SizedBox(height: 8),
          ],
          SectionHeader(title: tr("Available trucks", "ඇති ට්‍රක් රථ", "கிடைக்கும் லாரிகள்")),
          if (_loading) const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator())),
          if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
          if (!_loading && _error == null && _trips.isEmpty) emptyState(Icons.local_shipping_outlined, tr("No trucks right now", "දැනට ට්‍රක් රථ නැත", "இப்போது லாரிகள் இல்லை"), tr("Try another district, or check again later today.", "වෙනත් දිස්ත්‍රික්කයක් උත්සාහ කරන්න, නැතහොත් පසුව බලන්න.", "வேறு மாவட்டத்தை முயற்சிக்கவும் அல்லது பின்னர் பார்க்கவும்.")),
          ..._trips.map(_tripCard),
        ]),
      ),
    );
  }
}
