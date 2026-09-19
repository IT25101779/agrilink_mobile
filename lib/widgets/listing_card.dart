import 'package:flutter/material.dart';
import '../localization/app_locale.dart';
import '../localization/tr.dart';
import '../theme/app_theme.dart';
import 'crop_picker_field.dart';
import 'crop_thumbnail.dart';
import 'ui_kit.dart';

/// One of the farmer's own marketplace listings, shown with:
///  - the crop photo, quantity and live price,
///  - the FRESHNESS CLOCK (how much sell-by time is left, and the price
///    that results from it),
///  - the SELL-OR-HOLD advice for this listing (if the server has any),
///  - the actions that make sense for its status.
class MyListingCard extends StatefulWidget {
  final Map<String, dynamic> listing;
  final Map<String, dynamic>? advice;
  final VoidCallback? onEdit;
  final VoidCallback? onMarkSold;

  const MyListingCard({super.key, required this.listing, this.advice, this.onEdit, this.onMarkSold});

  @override
  State<MyListingCard> createState() => _MyListingCardState();
}

class _MyListingCardState extends State<MyListingCard> {
  bool _showWhy = false;

  // ---------- freshness helpers ----------

  Color _freshnessColor(String label) {
    switch (label) {
      case "fresh":
        return AppColors.forest;
      case "aging":
        return AppColors.gold;
      case "urgent":
      case "expired":
        return AppColors.danger;
      default:
        return AppColors.indigo;
    }
  }

  String _freshnessText(Map<String, dynamic> fresh) {
    final label = "${fresh["label"]}";
    final daysLeft = (fresh["daysLeft"] as num?)?.toInt() ?? 0;
    switch (label) {
      case "not_harvested":
        final days = (fresh["daysUntilHarvest"] as num?)?.toInt() ?? 0;
        return tr("Harvest in $days day${days == 1 ? "" : "s"}", "දින $days කින් අස්වැන්න", "$days நாட்களில் அறுவடை");
      case "fresh":
        return tr("Fresh · $daysLeft day${daysLeft == 1 ? "" : "s"} left", "නැවුම් · දින $daysLeft ක් ඉතිරියි", "புதியது · $daysLeft நாட்கள் மீதம்");
      case "aging":
        return tr("Ageing · $daysLeft day${daysLeft == 1 ? "" : "s"} left", "පරණ වෙමින් · දින $daysLeft ක් ඉතිරියි", "பழையதாகிறது · $daysLeft நாட்கள் மீதம்");
      case "urgent":
        return tr("Sell soon · $daysLeft day${daysLeft == 1 ? "" : "s"} left", "ඉක්මනින් විකුණන්න · දින $daysLeft ක් ඉතිරියි", "விரைவில் விற்கவும் · $daysLeft நாட்கள் மீதம்");
      default:
        return tr("Freshness window ended", "නැවුම්බව කාලය අවසන්", "புத்துணர்ச்சி காலம் முடிந்தது");
    }
  }

  // ---------- advice helpers ----------

  Color _adviceColor(String action) {
    switch (action) {
      case "sell_now":
        return AppColors.danger;
      case "hold":
        return AppColors.indigo;
      case "reprice_up":
      case "reprice_down":
        return AppColors.gold;
      default:
        return AppColors.forest;
    }
  }

  IconData _adviceIcon(String action) {
    switch (action) {
      case "sell_now":
        return Icons.bolt_rounded;
      case "hold":
        return Icons.hourglass_top_rounded;
      case "reprice_up":
        return Icons.trending_up_rounded;
      case "reprice_down":
        return Icons.trending_down_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  String _adviceTitle(String action) {
    switch (action) {
      case "sell_now":
        return tr("SELL NOW", "දැන්ම විකුණන්න", "இப்போதே விற்கவும்");
      case "hold":
        return tr("HOLD", "රඳවා ගන්න", "காத்திருக்கவும்");
      case "reprice_up":
        return tr("RAISE PRICE", "මිල ඉහළ දමන්න", "விலையை உயர்த்தவும்");
      case "reprice_down":
        return tr("LOWER PRICE", "මිල අඩු කරන්න", "விலையைக் குறைக்கவும்");
      default:
        return tr("ALL GOOD", "සියල්ල හොඳයි", "எல்லாம் நன்று");
    }
  }

  Widget _buildAdvice(BuildContext context, Map<String, dynamic> advice) {
    final action = "${advice["action"]}";
    final color = _adviceColor(action);
    final reasons = (advice["reasons"] as List? ?? []).map((r) => "$r").toList();

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
              Icon(_adviceIcon(action), size: 16, color: color),
              const SizedBox(width: 6),
              Text(_adviceTitle(action), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.4)),
              const Spacer(),
              if (reasons.isNotEmpty)
                InkWell(
                  onTap: () => setState(() => _showWhy = !_showWhy),
                  child: Text(
                    _showWhy ? tr("Hide", "සඟවන්න", "மறை") : tr("Why?", "ඇයි?", "ஏன்?"),
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text("${advice["headline"]}", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: inkOf(context), height: 1.3)),
          if (_showWhy) ...[
            const SizedBox(height: 6),
            ...reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 6),
                      child: Icon(Icons.circle, size: 5, color: mutedOf(context)),
                    ),
                    Expanded(child: Text(reason, style: TextStyle(fontSize: 12, color: mutedOf(context), height: 1.35))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocale.instance.t;
    final listing = widget.listing;
    final cropName = "${listing["cropType"]}";
    final status = "${listing["status"]}";
    final tier = "${listing["tier"]}";
    final asking = numOf(listing["currentPricePerKg"]);
    final fresh = listing["freshness"] is Map ? Map<String, dynamic>.from(listing["freshness"] as Map) : null;
    final livePrice = fresh != null ? numOf(fresh["effectivePricePerKg"], asking) : asking;
    final priceDropped = status == "listed" && livePrice < asking - 0.05;
    final crop = CropPickerField.findCrop(cropName);
    final isLive = status == "listed";

    Color statusColor;
    String statusLabel;
    switch (status) {
      case "listed":
        statusColor = AppColors.forest;
        statusLabel = tr("Live", "සජීවී", "செயலில்");
        break;
      case "reserved":
        statusColor = AppColors.gold;
        statusLabel = tr("Reserved", "වෙන් කර ඇත", "ஒதுக்கப்பட்டது");
        break;
      case "sold":
        statusColor = AppColors.inkMuted;
        statusLabel = tr("Sold", "විකුණා ඇත", "விற்கப்பட்டது");
        break;
      default:
        statusColor = AppColors.inkMuted;
        statusLabel = status;
    }

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
                    Text(cropName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      "${priceText(numOf(listing["quantityKg"]))} kg · ${tr("Grade", "ශ්‍රේණිය", "தரம்")} ${listing["qualityGrade"] ?? "A"}",
                      style: TextStyle(fontSize: 12.5, color: mutedOf(context)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusPill(label: statusLabel, color: statusColor),
                        if (tier == "secondary")
                          StatusPill(label: tr("Flash sale", "දැන්වීම් වට්ටම්", "அதிரடி விற்பனை"), color: AppColors.gold, icon: Icons.local_offer_rounded),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("LKR ${priceText(livePrice)}", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: priceDropped ? AppColors.gold : AppColors.forest)),
                  Text("/kg", style: TextStyle(fontSize: 11, color: mutedOf(context))),
                  if (priceDropped)
                    Text(
                      "LKR ${priceText(asking)}",
                      style: TextStyle(fontSize: 11, color: mutedOf(context), decoration: TextDecoration.lineThrough),
                    ),
                ],
              ),
            ],
          ),
          if (fresh != null && (isLive || status == "reserved")) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.timer_outlined, size: 14, color: _freshnessColor("${fresh["label"]}")),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _freshnessText(fresh),
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _freshnessColor("${fresh["label"]}")),
                  ),
                ),
              ],
            ),
            if ("${fresh["label"]}" != "not_harvested") ...[
              const SizedBox(height: 6),
              RoundedBar(
                value: numOf(fresh["percentRemaining"]) / 100,
                color: _freshnessColor("${fresh["label"]}"),
              ),
            ],
            if (priceDropped) ...[
              const SizedBox(height: 6),
              Text(
                tr("The price eases down a little each day as freshness runs out.", "නැවුම්බව අඩු වන විට මිල දිනපතා ටිකෙන් ටික අඩු වේ.", "புத்துணர்ச்சி குறையும்போது விலை தினமும் சிறிது சிறிதாகக் குறையும்."),
                style: TextStyle(fontSize: 11, color: mutedOf(context)),
              ),
            ],
          ],
          if (widget.advice != null && isLive) _buildAdvice(context, widget.advice!),
          if (isLive || status == "reserved") ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (isLive && widget.onEdit != null)
                  TextButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: Text(t("editListing"), style: const TextStyle(fontSize: 12.5)),
                  ),
                if (status == "reserved" && widget.onMarkSold != null)
                  TextButton.icon(
                    onPressed: widget.onMarkSold,
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                    label: Text(t("markAsSold"), style: const TextStyle(fontSize: 12.5)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
