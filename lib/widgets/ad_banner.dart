import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';

/// Fetches and displays a single active ad banner, targeted by whatever
/// context is passed in (crop type, timeline phase, district). Previously
/// the admin Ad Scheduler could create ads, but nothing in the farmer app
/// ever called GET /api/ads — this was the missing piece.
///
/// Renders nothing at all (SizedBox.shrink) while loading or if there are
/// no matching active ads, so it never leaves an empty placeholder box on
/// screen.
class AdBanner extends StatefulWidget {
  final String? cropType;
  final String? timelinePhase;
  final String? district;

  const AdBanner({super.key, this.cropType, this.timelinePhase, this.district});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  Map<String, dynamic>? _ad;
  bool _dismissed = false;
  bool _impressionTracked = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final result = await ApiService.getActiveAds(
      cropType: widget.cropType,
      timelinePhase: widget.timelinePhase,
      district: widget.district,
    );
    if (!mounted) return;
    if (result["success"] == true) {
      final ads = (result["data"] as List);
      if (ads.isNotEmpty) {
        setState(() => _ad = ads.first as Map<String, dynamic>);
        if (!_impressionTracked) {
          _impressionTracked = true;
          ApiService.trackAdImpression(_ad!["_id"]);
        }
      }
    }
  }

  Future<void> _handleTap() async {
    if (_ad == null) return;
    ApiService.trackAdClick(_ad!["_id"]);
    final url = _ad!["clickThroughUrl"] as String?;
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ad == null || _dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InkWell(
            onTap: _handleTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_ad!["bannerImageUrl"] != null)
                  Image.network(
                    _ad!["bannerImageUrl"],
                    height: 90,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          AppLocale.instance.t("sponsored"),
                          style: const TextStyle(fontSize: 9, color: AppColors.inkMuted, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _ad!["brandName"] ?? "",
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.inkMuted),
              onPressed: () => setState(() => _dismissed = true),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
