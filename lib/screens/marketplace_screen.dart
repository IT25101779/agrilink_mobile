import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../localization/app_locale.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/empty_state.dart';

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
  Map<String, dynamic>? _pricePrediction;
  List<dynamic> _myListings = [];
  bool _isLoadingListings = true;
  String _farmerId = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _farmerId = await AuthService.getUserId() ?? "";
    _loadListings();
  }

  Future<void> _loadListings() async {
    if (_farmerId.isEmpty) return;
    setState(() => _isLoadingListings = true);
    final result = await ApiService.getMyListings(_farmerId);
    setState(() {
      _myListings = result["success"] == true ? (result["data"] as List) : [];
      _isLoadingListings = false;
    });
  }

  Future<void> _checkPricePrediction() async {
    if (_cropController.text.trim().isEmpty) return;
    final result = await ApiService.getPricePrediction(_cropController.text.trim());
    if (result["success"] == true) {
      setState(() => _pricePrediction = result["data"]);
    } else {
      setState(() => _pricePrediction = null);
    }
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final result = await ApiService.createMarketplaceListing(
      farmerId: _farmerId,
      cropType: _cropController.text.trim(),
      quantityKg: double.parse(_quantityController.text),
      pricePerKg: double.parse(_priceController.text),
      harvestDate: DateTime.now().add(const Duration(days: 7)),
    );

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Listing created successfully!")),
      );
      _cropController.clear();
      _quantityController.clear();
      _priceController.clear();
      setState(() => _pricePrediction = null);
      _loadListings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed: ${result["message"] ?? "Could not reach server. Is the backend running?"}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t("listYourHarvest"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _cropController,
                  decoration: InputDecoration(labelText: t("cropTypeLabel"), border: const OutlineInputBorder()),
                  onChanged: (_) => _checkPricePrediction(),
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
                if (_pricePrediction != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "AI market prediction: LKR ${_pricePrediction!["predictedPricePerKg"]}/kg "
                      "(confidence: ${_pricePrediction!["confidence"]})",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitListing,
                    style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(t("listOnMarketplace")),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(t("myListings"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (_isLoadingListings)
            const Column(children: [ShimmerCard(), ShimmerCard()])
          else if (_myListings.isEmpty)
            EmptyState(icon: Icons.inventory_2_outlined, title: t("noListingsYet"))
          else
            ..._myListings.map((listing) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text("${listing["cropType"]} — ${listing["quantityKg"]}kg"),
                    subtitle: Text("LKR ${listing["currentPricePerKg"]}/kg • Tier: ${listing["tier"]}"),
                    trailing: Chip(
                      label: Text(listing["status"], style: const TextStyle(fontSize: 11)),
                      backgroundColor: listing["tier"] == "secondary" ? Colors.orange[100] : Colors.green[100],
                    ),
                  ),
                )),
        ],
      ),
    );
      },
    );
  }
}
