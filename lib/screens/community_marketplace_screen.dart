import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/smooth_route.dart';
import '../models/map_pin_data.dart';
import 'post_community_listing_screen.dart';
import 'my_community_listings_screen.dart';
import 'map_view_screen.dart';

const Map<String, IconData> _typeIcons = {
  "equipment_rental": Icons.agriculture_rounded,
  "seeds_for_sale": Icons.eco_rounded,
  "other": Icons.inventory_2_rounded,
};

/// Farmer-to-farmer marketplace for equipment rentals and seeds/inputs for
/// sale — distinct from the admin-managed Suppliers directory (business
/// listings) and MarketplaceListing (harvested produce). Any farmer can
/// post an item here; buyers see it and call the listed phone number
/// directly, same pattern as the Suppliers screen's Call button.
class CommunityMarketplaceScreen extends StatefulWidget {
  const CommunityMarketplaceScreen({super.key});

  @override
  State<CommunityMarketplaceScreen> createState() => _CommunityMarketplaceScreenState();
}

class _CommunityMarketplaceScreenState extends State<CommunityMarketplaceScreen> {
  String? _typeFilter;
  List<dynamic> _listings = [];
  bool _isLoading = true;
  String? _errorMessage;
  double _latitude = 7.2906;
  double _longitude = 80.6337;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Position? position;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.deniedForever) {
        position = await Geolocator.getCurrentPosition();
      }
    } catch (_) {}

    final latitude = position?.latitude ?? 7.2906;
    final longitude = position?.longitude ?? 80.6337;
    _latitude = latitude;
    _longitude = longitude;

    final result = await ApiService.getNearbyCommunityListings(
      latitude: latitude,
      longitude: longitude,
      radiusKm: 50,
      listingType: _typeFilter,
    );

    setState(() {
      _isLoading = false;
      if (result["success"] == true) {
        _listings = result["data"] as List;
      } else {
        _errorMessage = result["message"] ?? "Could not load listings.";
      }
    });
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openPostScreen() async {
    final created = await Navigator.push<bool>(
      context,
      SmoothRoute(page: const PostCommunityListingScreen()),
    );
    if (created == true) _load();
  }

  void _openMap() {
    final pins = _listings.map((l) {
      final coords = (l["location"]?["coordinates"] as List?) ?? [80.6337, 7.2906];
      final priceInfo = l["priceInfo"] as Map<String, dynamic>?;
      return MapPinData(
        name: l["title"] ?? "",
        latitude: (coords[1] as num).toDouble(),
        longitude: (coords[0] as num).toDouble(),
        phone: l["contactPhone"] as String?,
        subtitle: priceInfo != null ? "LKR ${priceInfo["amount"]} ${priceInfo["unit"]}" : null,
      );
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapViewScreen(
          title: AppLocale.instance.t("communityMarketplace"),
          pins: pins,
          initialLatitude: _latitude,
          initialLongitude: _longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        final filterLabels = <String?, String>{
          null: "All",
          "equipment_rental": t("equipmentRental"),
          "seeds_for_sale": t("seedsForSale"),
          "other": t("otherItem"),
        };

        return Scaffold(
          appBar: AppBar(
            title: Text(t("communityMarketplace")),
            actions: [
              IconButton(
                icon: const Icon(Icons.map_outlined),
                tooltip: t("mapView"),
                onPressed: _listings.isEmpty ? null : _openMap,
              ),
              IconButton(
                icon: const Icon(Icons.list_alt_rounded),
                tooltip: t("myRentalsAndSeeds"),
                onPressed: () => Navigator.push(
                  context,
                  SmoothRoute(page: const MyCommunityListingsScreen()),
                ).then((_) => _load()),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openPostScreen,
            backgroundColor: AppColors.gold,
            icon: const Icon(Icons.add_rounded),
            label: Text(t("postAnItem")),
          ),
          body: Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: filterLabels.entries.map((entry) {
                    final isSelected = _typeFilter == entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        selectedColor: AppColors.forest,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.ink, fontSize: 12.5),
                        onSelected: (_) {
                          setState(() => _typeFilter = entry.key);
                          _load();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? ListView(
                        padding: const EdgeInsets.all(16),
                        children: const [ShimmerCard(), ShimmerCard(), ShimmerCard()],
                      )
                    : _errorMessage != null
                        ? EmptyState(icon: Icons.error_outline_rounded, title: _errorMessage!)
                        : _listings.isEmpty
                            ? EmptyState(icon: Icons.storefront_outlined, title: t("noCommunityListingsFound"))
                            : RefreshIndicator(
                                onRefresh: _load,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                  itemCount: _listings.length,
                                  itemBuilder: (context, index) {
                                    final listing = _listings[index];
                                    final priceInfo = listing["priceInfo"] as Map<String, dynamic>?;

                                    return FadeSlideIn(
                                      delayMs: index * 50,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 38,
                                                  height: 38,
                                                  decoration: BoxDecoration(color: AppColors.forestLight, borderRadius: BorderRadius.circular(10)),
                                                  child: Icon(_typeIcons[listing["listingType"]] ?? Icons.inventory_2_rounded, color: AppColors.forest, size: 19),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(listing["title"] ?? "", style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                                      Text(
                                                        "${listing["farmer"]?["fullName"] ?? ""} \u00b7 ${listing["district"] ?? ""}",
                                                        style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(listing["description"] ?? "", style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
                                            if (priceInfo != null) ...[
                                              const SizedBox(height: 8),
                                              Text(
                                                "LKR ${priceInfo["amount"]} ${priceInfo["unit"]}",
                                                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.forest),
                                              ),
                                            ],
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: () => _call(listing["contactPhone"] ?? ""),
                                                icon: const Icon(Icons.call_rounded, size: 16),
                                                label: Text("${t("callToInquire")} \u00b7 ${listing["contactPhone"] ?? ""}"),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}
