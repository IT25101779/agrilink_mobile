import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../services/farm_api.dart';
import '../theme/app_theme.dart';
import '../widgets/farm_common.dart';
import '../widgets/trust_badge.dart';
import '../widgets/ui_kit.dart';
import '../widgets/user_avatar.dart';

/// The farmer's side of a sale: accept -> dispatch -> enter the buyer's delivery code -> confirm payment -> rate.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  Map<String, dynamic>? _myTrust;
  bool _loading = true;
  String? _error;
  int _tab = 0; // 0 active, 1 finished

  static const _tags = ["on_time", "good_quality", "fair_price", "honest_weight", "easy_to_deal_with", "paid_promptly", "late", "poor_quality", "hard_to_reach"];

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
    final result = await FarmApi.myOrders();
    final mine = await FarmApi.ratingsReceived();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result["success"] == true) {
        _orders = (result["data"] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else {
        _error = apiMessage(result);
      }
      if (mine["success"] == true) _myTrust = mine["trust"] as Map<String, dynamic>?;
    });
  }

  Future<void> _act(Future<Map<String, dynamic>> Function() call, {String? success}) async {
    final result = await call();
    if (!mounted) return;
    if (result["success"] == true) {
      if (success != null) showSnack(context, success);
      _load();
    } else {
      showSnack(context, apiMessage(result));
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case "placed":
        return tr("New order", "නව ඇණවුම", "புதிய ஆர்டர்");
      case "accepted":
        return tr("Accepted", "පිළිගත්තා", "ஏற்றுக்கொள்ளப்பட்டது");
      case "dispatched":
        return tr("On the way", "මගදී", "வழியில்");
      case "delivered":
        return tr("Delivered", "බෙදා හැරියා", "விநியோகிக்கப்பட்டது");
      case "paid":
        return tr("Paid", "ගෙවා ඇත", "செலுத்தப்பட்டது");
      default:
        return tr("Cancelled", "අවලංගුයි", "ரத்துசெய்யப்பட்டது");
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case "placed":
        return const Color(0xFFEA580C);
      case "accepted":
        return const Color(0xFF2563EB);
      case "dispatched":
        return const Color(0xFF7C3AED);
      case "delivered":
        return const Color(0xFF0E7490);
      case "paid":
        return AppColors.forest;
      default:
        return Colors.grey;
    }
  }

  String _tagLabel(String tag) {
    switch (tag) {
      case "on_time":
        return tr("On time", "නියමිත වේලාවට", "சரியான நேரத்தில்");
      case "good_quality":
        return tr("Good quality", "හොඳ තත්ත්වය", "நல்ல தரம்");
      case "fair_price":
        return tr("Fair price", "සාධාරණ මිල", "நியாயமான விலை");
      case "honest_weight":
        return tr("Honest weight", "අවංක බර", "நேர்மையான எடை");
      case "easy_to_deal_with":
        return tr("Easy to deal with", "ගනුදෙනුවට පහසුයි", "பழக எளிது");
      case "paid_promptly":
        return tr("Paid promptly", "වහාම ගෙවීය", "உடனே செலுத்தினார்");
      case "late":
        return tr("Late", "ප්‍රමාදයි", "தாமதம்");
      case "poor_quality":
        return tr("Poor quality", "දුර්වල තත්ත්වය", "மோசமான தரம்");
      default:
        return tr("Hard to reach", "සම්බන්ධ වීමට අපහසුයි", "தொடர்புகொள்ள கடினம்");
    }
  }

  Future<void> _dispatchSheet(Map<String, dynamic> o) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(tr("How will it be delivered?", "බෙදාහරින්නේ කෙසේද?", "எப்படி விநியோகிக்கப்படும்?"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          ListTile(leading: const Icon(Icons.local_shipping_rounded), title: Text(tr("By truck", "ට්‍රක් රථයෙන්", "லாரியில்")), subtitle: Text(tr("Tip: book a cheap return-load truck", "ඉඟිය: ආපසු ගමන් ට්‍රක් රථයක් වෙන්කරන්න", "குறிப்பு: மலிவான திரும்பும் லாரியை பதிவு செய்யுங்கள்")), onTap: () => Navigator.pop(context, "truck")),
          ListTile(leading: const Icon(Icons.agriculture_rounded), title: Text(tr("My own vehicle", "මගේ වාහනයෙන්", "என் வாகனத்தில்")), onTap: () => Navigator.pop(context, "self")),
          ListTile(leading: const Icon(Icons.storefront_rounded), title: Text(tr("Buyer collects it", "ගැනුම්කරු රැගෙන යයි", "வாங்குபவர் எடுத்துச் செல்வார்")), onTap: () => Navigator.pop(context, "pickup")),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (method == null) return;
    _act(() => FarmApi.dispatchOrder(o["id"], method), success: tr("On the way! The buyer now has a delivery code.", "මගදී! ගැනුම්කරුට දැන් බෙදාහැරීමේ කේතයක් ඇත.", "வழியில்! வாங்குபவருக்கு விநியோகக் குறியீடு கிடைத்தது."));
  }

  Future<void> _codeDialog(Map<String, dynamic> o) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr("Delivery code", "බෙදාහැරීමේ කේතය", "விநியோகக் குறியீடு")),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr("Ask the buyer for the 4-digit code in their app or website. Enter it only when the goods are handed over.", "ගැනුම්කරුගෙන් ඔවුන්ගේ යෙදුමේ/වෙබ් අඩවියේ ඇති ඉලක්කම් 4 කේතය ඉල්ලන්න. භාණ්ඩ භාර දෙන විට පමණක් ඇතුළත් කරන්න.", "வாங்குபவரிடம் அவர்களின் செயலி/இணையதளத்தில் உள்ள 4 இலக்கக் குறியீட்டைக் கேளுங்கள். பொருட்களை ஒப்படைக்கும்போது மட்டும் உள்ளிடுங்கள்."), style: const TextStyle(fontSize: 13, height: 1.4)),
          const SizedBox(height: 14),
          TextField(controller: controller, autofocus: true, keyboardType: TextInputType.number, maxLength: 4, textAlign: TextAlign.center, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: 10), decoration: const InputDecoration(counterText: "")),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr("Cancel", "අවලංගු", "ரத்து"))),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(tr("Confirm delivery", "බෙදාහැරීම තහවුරු කරන්න", "விநியோகத்தை உறுதிசெய்"))),
        ],
      ),
    );
    if (code == null || code.length != 4) return;
    _act(() => FarmApi.deliverOrder(o["id"], code), success: tr("Delivery confirmed!", "බෙදාහැරීම තහවුරු කළා!", "விநியோகம் உறுதிசெய்யப்பட்டது!"));
  }

  Future<void> _rateDialog(Map<String, dynamic> o) async {
    int stars = 5;
    final picked = <String>{};
    final comment = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr("Rate ${o["other"]["name"]}", "${o["other"]["name"]} ශ්‍රේණිගත කරන්න", "${o["other"]["name"]} மதிப்பிடு"), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(iconSize: 38, onPressed: () => setSheet(() => stars = i + 1), icon: Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded, color: const Color(0xFFF59E0B))))),
              Wrap(spacing: 8, runSpacing: 4, children: _tags.map((t) => FilterChip(label: Text(_tagLabel(t), style: const TextStyle(fontSize: 12)), selected: picked.contains(t), onSelected: (v) => setSheet(() => v ? picked.add(t) : picked.remove(t)))).toList()),
              const SizedBox(height: 10),
              TextField(controller: comment, maxLength: 200, maxLines: 2, decoration: InputDecoration(hintText: tr("Optional comment (no phone numbers)", "විකල්ප අදහසක් (දුරකථන අංක නැතිව)", "விருப்ப கருத்து (தொலைபேசி எண் வேண்டாம்)"))),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Submit rating", "ශ්‍රේණිගත කිරීම යවන්න", "மதிப்பீட்டை அனுப்பு")))),
            ]),
          ),
        ),
      ),
    );
    if (ok != true) return;
    _act(() => FarmApi.rate(o["id"], stars, picked.toList(), comment.text.trim()), success: tr("Thank you for rating!", "ශ්‍රේණිගත කිරීමට ස්තූතියි!", "மதிப்பீட்டிற்கு நன்றி!"));
  }

  Widget _stepper(String status) {
    const steps = ["placed", "accepted", "dispatched", "delivered", "paid"];
    final index = steps.indexOf(status);
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) return Expanded(child: Container(height: 2, color: (i ~/ 2) < index ? AppColors.forest : Colors.grey.shade300));
        final done = (i ~/ 2) <= index;
        return Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: done ? AppColors.forest : Colors.grey.shade300));
      }),
    );
  }

  Widget _card(Map<String, dynamic> o) {
    final status = "${o["status"]}";
    final other = Map<String, dynamic>.from(o["other"] as Map);
    final payment = Map<String, dynamic>.from((o["payment"] as Map?) ?? {});
    final actions = <Widget>[];
    if (status == "placed") {
      actions.addAll([
        Expanded(child: OutlinedButton(onPressed: () => _act(() => FarmApi.cancelOrder(o["id"], "Declined by farmer")), child: Text(tr("Decline", "ප්‍රතික්ෂේප", "நிராகரி")))),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton(onPressed: () => _act(() => FarmApi.acceptOrder(o["id"])), child: Text(tr("Accept", "පිළිගන්න", "ஏற்கவும்")))),
      ]);
    } else if (status == "accepted") {
      actions.addAll([
        Expanded(child: OutlinedButton(onPressed: () => _act(() => FarmApi.cancelOrder(o["id"], "Cancelled by farmer")), child: Text(tr("Cancel", "අවලංගු", "ரத்து")))),
        const SizedBox(width: 10),
        Expanded(child: ElevatedButton.icon(onPressed: () => _dispatchSheet(o), icon: const Icon(Icons.local_shipping_rounded, size: 18), label: Text(tr("Dispatch", "යවන්න", "அனுப்பு")))),
      ]);
    } else if (status == "dispatched") {
      actions.add(Expanded(child: ElevatedButton.icon(onPressed: () => _codeDialog(o), icon: const Icon(Icons.pin_rounded, size: 18), label: Text(tr("Enter delivery code", "බෙදාහැරීමේ කේතය ඇතුළත් කරන්න", "விநியோகக் குறியீட்டை உள்ளிடு")))));
    } else if (status == "delivered" && payment["buyerMarkedAt"] != null && payment["farmerConfirmedAt"] == null) {
      actions.add(Expanded(child: ElevatedButton.icon(onPressed: () => _act(() => FarmApi.confirmPayment(o["id"]), success: tr("Sale complete!", "විකිණීම සම්පූර්ණයි!", "விற்பனை முடிந்தது!")), icon: const Icon(Icons.payments_rounded, size: 18), label: Text(tr("Confirm payment received", "ගෙවීම ලැබුණු බව තහවුරු කරන්න", "பணம் கிடைத்ததை உறுதிசெய்")))));
    }
    final hint = status == "dispatched" && (o["delivery"]?["codeLocked"] == true)
        ? tr("Too many wrong codes. Ask the buyer to generate a new code.", "වැරදි කේත වැඩියි. නව කේතයක් ලබා ගන්නා ලෙස ගැනුම්කරුගෙන් ඉල්ලන්න.", "தவறான குறியீடுகள் அதிகம். புதிய குறியீட்டை உருவாக்கச் சொல்லுங்கள்.")
        : status == "delivered" && payment["buyerMarkedAt"] == null
            ? tr("Delivered. Waiting for the buyer to pay.", "බෙදා හැරියා. ගැනුම්කරු ගෙවන තෙක් රැඳී සිටී.", "விநியோகிக்கப்பட்டது. வாங்குபவர் செலுத்தக் காத்திருக்கிறது.")
            : status == "cancelled"
                ? "${o["cancelReason"] ?? ""}"
                : "";

    return SoftCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text("${cropLabel("${o["cropType"]}")} · ${o["quantityKg"]} kg", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          StatusPill(label: _statusLabel(status), color: _statusColor(status)),
        ]),
        const SizedBox(height: 4),
        Text("${lkr(numOf(o["totalLkr"]))}  ·  LKR ${priceText(numOf(o["pricePerKg"]))}/kg", style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
        const SizedBox(height: 12),
        Row(children: [
          UserAvatar(userId: other["id"] as String?, name: "${other["name"]}", size: 36, hasPicture: other["hasAvatar"] == true),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${other["name"]}", style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            TrustBadge(trust: other["trust"] as Map?, compact: true),
          ])),
          if (other["phone"] != null) IconButton(onPressed: () => callPhone("${other["phone"]}"), icon: const Icon(Icons.call_rounded, color: AppColors.forest)),
        ]),
        if (status != "cancelled") ...[const SizedBox(height: 14), _stepper(status)],
        if (hint.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(hint, style: TextStyle(fontSize: 12.5, color: status == "cancelled" ? Colors.grey : AppColors.inkMuted))),
        if (actions.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 14), child: Row(children: actions)),
        if (o["canRate"] == true) Padding(padding: const EdgeInsets.only(top: 10), child: SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _rateDialog(o), icon: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)), label: Text(tr("Rate the buyer", "ගැනුම්කරුට ශ්‍රේණිගත කරන්න", "வாங்குபவரை மதிப்பிடு"))))),
        if (o["myRating"] != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text("${tr("You rated", "ඔබේ ශ්‍රේණිගත කිරීම", "உங்கள் மதிப்பீடு")}: ${"★" * (o["myRating"] as int)}", style: const TextStyle(fontSize: 12, color: Color(0xFFB45309), fontWeight: FontWeight.w700))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = _orders.where((o) => !["paid", "cancelled"].contains(o["status"]) || o["canRate"] == true).toList();
    final finished = _orders.where((o) => ["paid", "cancelled"].contains(o["status"])).toList();
    final shown = _tab == 0 ? active : finished;
    return Scaffold(
      appBar: AppBar(title: Text(tr("My orders", "මගේ ඇණවුම්", "என் ஆர்டர்கள்"))),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 40), children: [
                if (_myTrust != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [Text("${tr("Your trust score", "ඔබේ විශ්වාස ලකුණු", "உங்கள் நம்பிக்கை மதிப்பெண்")}:  ", style: const TextStyle(fontSize: 13)), TrustBadge(trust: _myTrust)])),
                Row(children: [
                  ChoiceChip(label: Text("${tr("Active", "ක්‍රියාත්මක", "செயலில்")} (${active.length})"), selected: _tab == 0, onSelected: (_) => setState(() => _tab = 0)),
                  const SizedBox(width: 8),
                  ChoiceChip(label: Text("${tr("Finished", "අවසන්", "முடிந்தவை")} (${finished.length})"), selected: _tab == 1, onSelected: (_) => setState(() => _tab = 1)),
                ]),
                const SizedBox(height: 12),
                if (_error != null) InfoBanner(icon: Icons.error_outline_rounded, text: _error!, color: AppColors.danger),
                if (shown.isEmpty && _error == null) emptyState(Icons.receipt_long_rounded, tr("No orders here yet", "තවම ඇණවුම් නැත", "இன்னும் ஆர்டர்கள் இல்லை"), tr("When a buyer orders your produce, it appears here.", "ගැනුම්කරුවෙකු ඔබේ නිෂ්පාදන ඇණවුම් කරන විට එය මෙහි පෙන්වයි.", "வாங்குபவர் உங்கள் விளைபொருளை ஆர்டர் செய்யும்போது இங்கே தோன்றும்.")),
                ...shown.map(_card),
              ]),
      ),
    );
  }
}
