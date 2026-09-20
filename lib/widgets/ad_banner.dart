import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/tr.dart';
import '../services/api_service.dart';
import '../services/app_http.dart';

/// One active ad for the place it is shown: marketplace, logistics, driver,
/// timeline or scanner. Ads with a picture show the picture; ads without one
/// are drawn as a coloured card from the headline / text the admin wrote.
///
/// Draws nothing at all while loading or when there is no ad — never an empty box.
class AdBanner extends StatefulWidget {
  final String placement;
  final String? cropType;
  final String? timelinePhase;
  final String? district;

  const AdBanner({super.key, this.placement = "marketplace", this.cropType, this.timelinePhase, this.district});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  Map<String, dynamic>? _ad;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final query = <String>[
      "activeOnly=true",
      "placement=${widget.placement}",
      if (widget.cropType != null) "cropType=${Uri.encodeQueryComponent(widget.cropType!)}",
      if (widget.timelinePhase != null) "timelinePhase=${widget.timelinePhase}",
      if (widget.district != null) "district=${Uri.encodeQueryComponent(widget.district!)}",
    ].join("&");
    try {
      final r = await AppHttp.get(Uri.parse("${ApiService.baseUrl}/ads?$query"));
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final ads = (data["data"] as List? ?? []);
      if (!mounted || ads.isEmpty) return;
      // Show a different ad each time so every advertiser gets a turn.
      final ad = Map<String, dynamic>.from(ads[DateTime.now().millisecond % ads.length] as Map);
      setState(() => _ad = ad);
      AppHttp.post(Uri.parse("${ApiService.baseUrl}/ads/${ad["_id"]}/impression"), headers: {"Content-Type": "application/json"}, body: jsonEncode({"placement": widget.placement}));
    } catch (_) {
      // an ad that fails to load is simply not shown
    }
  }

  Future<void> _open() async {
    final ad = _ad;
    if (ad == null) return;
    AppHttp.post(Uri.parse("${ApiService.baseUrl}/ads/${ad["_id"]}/click"));
    final uri = Uri.tryParse("${ad["clickThroughUrl"] ?? ""}");
    if (uri != null && await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Color _accent() {
    final hex = "${_ad?["accentColor"] ?? ""}".replaceAll("#", "");
    final value = int.tryParse(hex.length == 6 ? "FF$hex" : "", radix: 16);
    return value == null ? const Color(0xFF0B5D3B) : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || _dismissed) return const SizedBox.shrink();
    final image = "${ad["bannerImageUrl"] ?? ""}";
    final sponsored = tr("Sponsored", "අනුග්‍රහය", "விளம்பரம்");

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 5))]),
      child: Stack(
        children: [
          InkWell(
            onTap: _open,
            child: image.isNotEmpty ? _pictureAd(image, ad) : _textAd(ad),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Row(
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10)), child: Text(sponsored, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700))),
                const SizedBox(width: 4),
                InkWell(onTap: () => setState(() => _dismissed = true), child: Container(padding: const EdgeInsets.all(3), decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 13, color: Colors.white))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pictureAd(String image, Map<String, dynamic> ad) => Image.network(image, width: double.infinity, height: 110, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _textAd(ad));

  Widget _textAd(Map<String, dynamic> ad) {
    final accent = _accent();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [accent, Color.lerp(accent, Colors.black, 0.28)!], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Row(
        children: [
          Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(16)), child: Text("${ad["emoji"] ?? "📢"}", style: const TextStyle(fontSize: 28))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${ad["brandName"]}".toUpperCase(), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
                const SizedBox(height: 2),
                Text("${ad["headline"] ?? ""}", style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800, height: 1.2)),
                if ("${ad["body"] ?? ""}".isNotEmpty) Padding(padding: const EdgeInsets.only(top: 3), child: Text("${ad["body"]}", maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.88), fontSize: 12, height: 1.3))),
                const SizedBox(height: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Text("${ad["ctaLabel"] ?? "Learn more"}", style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w800))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
