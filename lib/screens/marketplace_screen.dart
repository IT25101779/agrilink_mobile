import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/insights_api.dart';
import '../localization/app_locale.dart';
import '../localization/tr.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state.dart';
import '../widgets/ad_banner.dart';
import '../widgets/crop_picker_field.dart';
import '../widgets/listing_card.dart';
import '../widgets/price_forecast_card.dart';
import '../widgets/ui_kit.dart';
import '../theme/app_theme.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cropController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isSubmitting = false;
  String _forecastCrop = "";
  // When the produce is (or will be) harvested: 0 = today, 3 / 7 = in that many days.
  // The Freshness Clock starts counting from this date.
  int _harvestInDays = 0;
  List<dynamic> _myListings = [];
  Map<String, Map<String, dynamic>> _adviceById = {};
  bool _isLoadingListings = true;
  String _farmerId = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _cropController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    _farmerId = await AuthService.getUserId() ?? "";
    _loadListings();
  }

  Future<void> _loadListings() async {
    if (_farmerId.isEmpty) return;
    setState(() => _isLoadingListings = true);
    final result = await InsightsApi.getMyListings(_farmerId);
    if (!mounted) return;
    setState(() {
      _myListings = result["success"] == true ? (result["data"] as List) : [];
      _isLoadingListings = false;
    });
    _loadAdvice();
  }

  /// Sell-or-Hold advice for every live listing (failures are silent — the
  /// listings still show, just without advice).
  Future<void> _loadAdvice() async {
    final result = await InsightsApi.getSellOrHold();
    if (!mounted || result["success"] != true) return;
    final map = <String, Map<String, dynamic>>{};
    for (final item in (result["data"] as List)) {
      final advice = Map<String, dynamic>.from(item as Map);
      map["${advice["listingId"]}"] = advice;
    }
    setState(() => _adviceById = map);
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final result = await ApiService.createMarketplaceListing(
      farmerId: _farmerId,
      cropType: _cropController.text.trim(),
      quantityKg: double.parse(_quantityController.text),
      pricePerKg: double.parse(_priceController.text),
      harvestDate: DateTime.now().add(Duration(days: _harvestInDays)),
    );

    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Listing created successfully!", "දැන්වීම සාර්ථකව සාදන ලදී!"))),
      );
      _cropController.clear();
      _quantityController.clear();
      _priceController.clear();
      setState(() => _forecastCrop = "");
      _loadListings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${result["message"] ?? "Could not reach server."}")),
      );
    }
  }

  Future<void> _openEditDialog(Map<String, dynamic> listing) async {
    final t = AppLocale.instance.t;
    final quantityController = TextEditingController(text: "${listing["quantityKg"]}");
    final priceController = TextEditingController(text: "${listing["currentPricePerKg"]}");
    String qualityGrade = listing["qualityGrade"] ?? "A";

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text("${t("editListing")} — ${listing["cropType"]}"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t("quantityKg")),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t("askingPrice")),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: qualityGrade,
                  decoration: const InputDecoration(labelText: "Quality grade"),
                  items: ["A", "B", "C"].map((g) => DropdownMenuItem(value: g, child: Text("Grade $g"))).toList(),
                  onChanged: (v) => setDialogState(() => qualityGrade = v ?? "A"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t("cancel"))),
            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(t("saveChanges"))),
          ],
        ),
      ),
    );

    if (saved != true) return;
    final quantity = double.tryParse(quantityController.text);
    final price = double.tryParse(priceController.text);
    if (quantity == null || price == null) return;

    final result = await ApiService.updateMarketplaceListing(
      listingId: listing["_id"],
      farmerId: _farmerId,
      quantityKg: quantity,
      pricePerKg: price,
      qualityGrade: qualityGrade,
    );

    if (!mounted) return;
    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t("listingUpdated"))));
      _loadListings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result["message"] ?? "Failed to update listing.")));
    }
  }

  Future<void> _markAsSold(Map<String, dynamic> listing) async {
    final t = AppLocale.instance.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(t("markAsSold")),
        content: Text(t("markAsSoldConfirm")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t("cancel"))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(t("markAsSold"))),
        ],
      ),
    );
    if (confirmed != true) return;

    final result = await ApiService.completeSale(listingId: listing["_id"], confirmedByUserId: _farmerId);
    if (!mounted) return;
    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t("saleCompleted"))));
      _loadListings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result["message"] ?? "Failed to complete sale.")));
    }
  }

  Widget _harvestChip(int days, String label) {
    final selected = _harvestInDays == days;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12.5)),
        selected: selected,
        selectedColor: AppColors.forest,
        labelStyle: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600),
        onSelected: (_) => setState(() => _harvestInDays = days),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return RefreshIndicator(
          onRefresh: _loadListings,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdBanner(),
                SectionHeader(title: t("listYourHarvest")),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CropPickerField(
                        controller: _cropController,
                        label: t("cropTypeLabel"),
                        onSelected: (crop) => setState(() => _forecastCrop = crop),
                        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: t("quantityKg"), border: const OutlineInputBorder()),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? "Enter a valid number" : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(labelText: t("askingPrice"), border: const OutlineInputBorder()),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? "Enter a valid number" : null,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(tr("When is it harvested?", "අස්වැන්න නෙලන්නේ කවදාද?"),
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: mutedOf(context))),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          children: [
                            _harvestChip(0, tr("Today", "අද")),
                            _harvestChip(3, tr("In 3 days", "දින 3කින්")),
                            _harvestChip(7, tr("In 7 days", "දින 7කින්")),
                          ],
                        ),
                      ),
                      if (_forecastCrop.isNotEmpty)
                        PriceForecastCard(
                          cropType: _forecastCrop,
                          onUsePrice: (price) => setState(() => _priceController.text = priceText(price)),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitListing,
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: _isSubmitting
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(t("listOnMarketplace")),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SectionHeader(
                  title: t("myListings"),
                  subtitle: tr(
                    "Live advice on each listing: freshness, market price trend and nearby supply.",
                    "එක් එක් දැන්වීම සඳහා සජීවී උපදෙස්: නැවුම්බව, මිල ප්‍රවණතාව සහ අසල සැපයුම.",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: tr("Refresh", "නැවුම් කරන්න"),
                    onPressed: _loadListings,
                  ),
                ),
                if (_isLoadingListings)
                  const Column(children: [ShimmerCard(), ShimmerCard()])
                else if (_myListings.isEmpty)
                  EmptyState(icon: Icons.inventory_2_outlined, title: t("noListingsYet"))
                else
                  ..._myListings.map((item) {
                    final listing = Map<String, dynamic>.from(item as Map);
                    return MyListingCard(
                      key: ValueKey(listing["_id"]),
                      listing: listing,
                      advice: _adviceById["${listing["_id"]}"],
                      onEdit: () => _openEditDialog(listing),
                      onMarkSold: () => _markAsSold(listing),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
