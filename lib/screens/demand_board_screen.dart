import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_locale.dart';
import '../localization/tr.dart';
import '../services/auth_service.dart';
import '../services/insights_api.dart';
import '../theme/app_theme.dart';
import '../widgets/crop_picker_field.dart';
import '../widgets/crop_thumbnail.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/ui_kit.dart';

/// BUYER REQUESTS (the Demand Board). Buyers post what they need — "300 kg of
/// beans by Friday, up to LKR 420/kg" — and farmers answer with an offer
/// BEFORE harvesting. Farmers never see each other's offer prices; the buyer's
/// phone number appears only after the buyer accepts your offer.
class DemandBoardScreen extends StatefulWidget {
  const DemandBoardScreen({super.key});

  @override
  State<DemandBoardScreen> createState() => _DemandBoardScreenState();
}

class _DemandBoardScreenState extends State<DemandBoardScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String? _district;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _district = await AuthService.getDistrict();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await InsightsApi.listDemandRequests(district: _district);
    if (!mounted) return;
    setState(() {
      _requests = result["success"] == true
          ? (result["data"] as List).map((r) => Map<String, dynamic>.from(r as Map)).toList()
          : [];
      _loading = false;
    });
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _offer(Map<String, dynamic> request) async {
    final remaining = numOf(request["remainingKg"]);
    final maxPrice = numOf(request["maxPricePerKg"]);
    final qtyController = TextEditingController(text: priceText(remaining));
    final priceController = TextEditingController(text: priceText(maxPrice));
    final messageController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text("${tr("Offer", "පිරිනැමුම")} — ${request["cropType"]}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr("Quantity you can supply (kg)", "ඔබට සැපයිය හැකි ප්‍රමාණය (කි.ග්‍රෑ.)"),
                  helperText: tr("Up to ${priceText(remaining)} kg", "උපරිම කි.ග්‍රෑ. ${priceText(remaining)}"),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: tr("Your price per kg (LKR)", "ඔබේ මිල (LKR/කි.ග්‍රෑ.)"),
                  helperText: tr("Buyer's maximum: LKR ${priceText(maxPrice)}", "ගැනුම්කරුගේ උපරිමය: LKR ${priceText(maxPrice)}"),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: messageController,
                maxLength: 300,
                decoration: InputDecoration(labelText: tr("Message (optional)", "පණිවිඩය (අත්‍යවශ්‍ය නොවේ)")),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr("Cancel", "අවලංගු"))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Send offer", "පිරිනැමුම යවන්න"))),
        ],
      ),
    );

    final qty = double.tryParse(qtyController.text);
    final price = double.tryParse(priceController.text);
    final message = messageController.text.trim();
    qtyController.dispose();
    priceController.dispose();
    messageController.dispose();
    if (confirmed != true) return;
    if (qty == null || price == null || qty < 1 || price < 1) {
      _toast(tr("Please enter a valid quantity and price.", "කරුණාකර වලංගු ප්‍රමාණයක් සහ මිලක් ඇතුළත් කරන්න."));
      return;
    }

    final result = await InsightsApi.makeOffer(requestId: "${request["_id"]}", quantityKg: qty, pricePerKg: price, message: message);
    _toast(result["message"]?.toString() ?? tr("Something went wrong.", "යම්කිසි දෝෂයක් සිදු විය."));
    _load();
  }

  Future<void> _withdraw(Map<String, dynamic> request, Map<String, dynamic> offer) async {
    final result = await InsightsApi.withdrawOffer("${request["_id"]}", "${offer["_id"]}");
    _toast(result["message"]?.toString() ?? tr("Done.", "සම්පූර්ණයි."));
    _load();
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Widget _offerBox(Map<String, dynamic> request, Map<String, dynamic> offer) {
    final status = "${offer["status"]}";
    Color color;
    String label;
    switch (status) {
      case "accepted":
        color = AppColors.forest;
        label = tr("Accepted", "පිළිගත්තා");
        break;
      case "declined":
        color = AppColors.danger;
        label = tr("Declined", "ප්‍රතික්ෂේප කළා");
        break;
      case "withdrawn":
        color = AppColors.inkMuted;
        label = tr("Withdrawn", "ඉවත් කළා");
        break;
      default:
        color = AppColors.indigo;
        label = tr("Offer sent", "පිරිනැමුම යවා ඇත");
    }
    final phone = offer["buyerPhone"];
    final acceptedKg = numOf(offer["acceptedKg"]);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: tintOf(context, color), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusPill(label: label, color: color),
              const Spacer(),
              if (status == "offered")
                TextButton(onPressed: () => _withdraw(request, offer), child: Text(tr("Withdraw", "ඉවත් කරන්න"), style: const TextStyle(fontSize: 12.5))),
            ],
          ),
          Text(
            tr(
              "Your offer: ${priceText(numOf(offer["quantityKg"]))} kg at LKR ${priceText(numOf(offer["pricePerKg"]))}/kg",
              "ඔබේ පිරිනැමුම: කි.ග්‍රෑ. ${priceText(numOf(offer["quantityKg"]))} @ LKR ${priceText(numOf(offer["pricePerKg"]))}/කි.ග්‍රෑ.",
            ),
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          if (status == "accepted") ...[
            const SizedBox(height: 4),
            Text(
              tr("Accepted quantity: ${priceText(acceptedKg)} kg", "පිළිගත් ප්‍රමාණය: කි.ග්‍රෑ. ${priceText(acceptedKg)}"),
              style: const TextStyle(fontSize: 12.5),
            ),
            if (phone != null && "$phone".isNotEmpty)
              TextButton.icon(
                onPressed: () => _call("$phone"),
                icon: const Icon(Icons.call_rounded, size: 16),
                label: Text("${tr("Call buyer", "ගැනුම්කරුට අමතන්න")}: $phone"),
              ),
          ],
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> request) {
    final crop = CropPickerField.findCrop("${request["cropType"]}");
    final needed = DateTime.tryParse("${request["neededBy"]}");
    final offersCount = (request["offersCount"] as num?)?.toInt() ?? 0;
    final offer = request["myOffer"] is Map ? Map<String, dynamic>.from(request["myOffer"] as Map) : null;
    final district = "${request["district"] ?? ""}";
    final canOffer = offer == null || offer["status"] == "withdrawn" || offer["status"] == "declined";

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (crop != null)
                CropThumbnail(wikiImageTitle: crop.wikiImageTitle, size: 48)
              else
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: tintOf(context, AppColors.forest), borderRadius: BorderRadius.circular(13)),
                  child: const Icon(Icons.eco_rounded, color: AppColors.forest),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${request["cropType"]}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text("${request["buyerName"]}", style: TextStyle(fontSize: 12.5, color: mutedOf(context))),
                    Text(
                      district.isEmpty ? tr("Any district", "ඕනෑම දිස්ත්‍රික්කයක්") : district,
                      style: TextStyle(fontSize: 12, color: mutedOf(context)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(tr("up to", "උපරිම"), style: TextStyle(fontSize: 10.5, color: mutedOf(context))),
                  Text("LKR ${priceText(numOf(request["maxPricePerKg"]))}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.forest)),
                  Text("/kg", style: TextStyle(fontSize: 11, color: mutedOf(context))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusPill(
                label: tr("${priceText(numOf(request["remainingKg"]))} kg needed", "කි.ග්‍රෑ. ${priceText(numOf(request["remainingKg"]))} අවශ්‍යයි"),
                color: AppColors.forest,
                icon: Icons.inventory_2_outlined,
              ),
              if (needed != null)
                StatusPill(
                  label: "${tr("By", "දිනට")} ${DateFormat("d MMM").format(needed.toLocal())}",
                  color: AppColors.gold,
                  icon: Icons.event_rounded,
                ),
              StatusPill(
                label: tr("$offersCount offer${offersCount == 1 ? "" : "s"}", "පිරිනැමුම් $offersCount"),
                color: AppColors.inkMuted,
              ),
            ],
          ),
          if ("${request["note"] ?? ""}".isNotEmpty) ...[
            const SizedBox(height: 8),
            Text("${request["note"]}", style: TextStyle(fontSize: 12.5, color: mutedOf(context), height: 1.35)),
          ],
          if (offer != null) _offerBox(request, offer),
          if (canOffer) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _offer(request),
                icon: const Icon(Icons.send_rounded, size: 16),
                label: Text(tr("Make an offer", "පිරිනැමුමක් යවන්න")),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              InfoBanner(
                icon: Icons.campaign_rounded,
                color: AppColors.indigo,
                text: tr(
                  "Buyers post what they need. Offer before you harvest — and use it to decide what to plant next.",
                  "ගැනුම්කරුවන් තමන්ට අවශ්‍ය දේ පළ කරයි. අස්වැන්න නෙළීමට පෙර පිරිනමන්න — ඊළඟට වගා කළ යුතු දේ තීරණය කිරීමටත් මෙය භාවිත කරන්න.",
                ),
              ),
              if (_loading)
                const Column(children: [ShimmerCard(), ShimmerCard()])
              else if (_requests.isEmpty)
                EmptyState(
                  icon: Icons.campaign_outlined,
                  title: tr("No open buyer requests", "විවෘත ගැනුම්කරු ඉල්ලීම් නැත"),
                  subtitle: tr("New requests from buyers will appear here.", "ගැනුම්කරුවන්ගේ නව ඉල්ලීම් මෙහි පෙන්වයි."),
                )
              else
                ..._requests.map(_card),
            ],
          ),
        );
      },
    );
  }
}
