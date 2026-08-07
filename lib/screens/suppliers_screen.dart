import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/empty_state.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/shimmer_loading.dart';

const Map<String, IconData> _typeIcons = {
  "seed_store": Icons.eco_rounded,
  "fertilizer_store": Icons.science_rounded,
  "tool_store": Icons.handyman_rounded,
  "equipment_rental": Icons.agriculture_rounded,
};

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String? _typeFilter;
  List<dynamic> _suppliers = [];
  bool _isLoading = true;
  String? _errorMessage;

  final Map<String?, String> _filterLabels = {
    null: "All",
    "seed_store": "Seeds",
    "fertilizer_store": "Fertilizer",
    "tool_store": "Tools",
    "equipment_rental": "Rentals",
  };

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

    final result = await ApiService.getNearbySuppliers(
      latitude: latitude,
      longitude: longitude,
      radiusKm: 50,
      type: _typeFilter,
    );

    setState(() {
      _isLoading = false;
      if (result["success"] == true) {
        _suppliers = result["data"] as List;
      } else {
        _errorMessage = result["message"] ?? "Could not load suppliers.";
      }
    });
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return Scaffold(
          appBar: AppBar(title: Text(t("nearbySuppliers"))),
          body: Column(
            children: [
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  children: _filterLabels.entries.map((entry) {
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
                        : _suppliers.isEmpty
                            ? EmptyState(icon: Icons.storefront_outlined, title: t("noSuppliersFound"))
                            : RefreshIndicator(
                                onRefresh: _load,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _suppliers.length,
                                  itemBuilder: (context, index) {
                                    final supplier = _suppliers[index];
                                    final rentalEquipment = (supplier["rentalEquipment"] as List?) ?? [];
                                    final items = (supplier["itemsAvailable"] as List?) ?? [];

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
                                                  child: Icon(_typeIcons[supplier["supplierType"]] ?? Icons.storefront, color: AppColors.forest, size: 19),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(supplier["businessName"], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                                      Text(supplier["district"] ?? "", style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                                                    ],
                                                  ),
                                                ),
                                                if (supplier["isVerified"] == true)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(color: AppColors.forestLight, borderRadius: BorderRadius.circular(20)),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(Icons.verified_rounded, size: 12, color: AppColors.forest),
                                                        const SizedBox(width: 3),
                                                        Text(t("verified"), style: const TextStyle(fontSize: 10, color: AppColors.forest, fontWeight: FontWeight.w700)),
                                                      ],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(supplier["address"] ?? "", style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
                                            if (items.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 6,
                                                runSpacing: 6,
                                                children: items
                                                    .map<Widget>((item) => Chip(
                                                          label: Text(item, style: const TextStyle(fontSize: 10.5)),
                                                          visualDensity: VisualDensity.compact,
                                                          backgroundColor: AppColors.background,
                                                        ))
                                                    .toList(),
                                              ),
                                            ],
                                            if (rentalEquipment.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              ...rentalEquipment.map((eq) => Padding(
                                                    padding: const EdgeInsets.only(bottom: 3),
                                                    child: Text(
                                                      "${eq["equipmentName"]} — ${t("dailyRate")}: LKR ${eq["dailyRateLkr"]}",
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  )),
                                            ],
                                            const SizedBox(height: 10),
                                            SizedBox(
                                              width: double.infinity,
                                              child: OutlinedButton.icon(
                                                onPressed: () => _call(supplier["contactPhone"]),
                                                icon: const Icon(Icons.call_rounded, size: 16),
                                                label: Text("${t("call")} · ${supplier["contactPhone"]}"),
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
