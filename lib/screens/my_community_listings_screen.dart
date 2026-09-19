import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/empty_state.dart';
import '../widgets/shimmer_loading.dart';

class MyCommunityListingsScreen extends StatefulWidget {
  const MyCommunityListingsScreen({super.key});

  @override
  State<MyCommunityListingsScreen> createState() => _MyCommunityListingsScreenState();
}

class _MyCommunityListingsScreenState extends State<MyCommunityListingsScreen> {
  List<dynamic> _listings = [];
  bool _isLoading = true;
  String _farmerId = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _farmerId = await AuthService.getUserId() ?? "";
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final result = await ApiService.getMyCommunityListings(_farmerId);
    setState(() {
      _listings = result["success"] == true ? (result["data"] as List) : [];
      _isLoading = false;
    });
  }

  Future<void> _toggleActive(Map<String, dynamic> listing) async {
    await ApiService.updateCommunityListing(
      listingId: listing["_id"],
      farmerId: _farmerId,
      isActive: !(listing["isActive"] == true),
    );
    _load();
  }

  Future<void> _delete(Map<String, dynamic> listing) async {
    final t = AppLocale.instance.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t("deleteListing")),
        content: Text("\"${listing["title"]}\"?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t("cancel"))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t("deleteListing")),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ApiService.deleteCommunityListing(listingId: listing["_id"], farmerId: _farmerId);
    _load();
  }

  Future<void> _editDialog(Map<String, dynamic> listing) async {
    final t = AppLocale.instance.t;
    final titleController = TextEditingController(text: listing["title"]);
    final descriptionController = TextEditingController(text: listing["description"]);
    final priceController = TextEditingController(text: "${listing["priceInfo"]?["amount"] ?? ""}");
    final unitController = TextEditingController(text: listing["priceInfo"]?["unit"] ?? "");

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(t("editListing")),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: t("itemTitle"))),
              const SizedBox(height: 10),
              TextField(controller: descriptionController, maxLines: 3, decoration: InputDecoration(labelText: t("itemDescription"))),
              const SizedBox(height: 10),
              TextField(controller: priceController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: t("priceAmount"))),
              const SizedBox(height: 10),
              TextField(controller: unitController, decoration: InputDecoration(labelText: t("priceUnit"))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t("cancel"))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(t("saveChanges"))),
        ],
      ),
    );

    if (saved != true) return;
    final price = double.tryParse(priceController.text);

    await ApiService.updateCommunityListing(
      listingId: listing["_id"],
      farmerId: _farmerId,
      title: titleController.text.trim(),
      description: descriptionController.text.trim(),
      priceAmount: price,
      priceUnit: unitController.text.trim(),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return Scaffold(
          appBar: AppBar(title: Text(t("myRentalsAndSeeds"))),
          body: _isLoading
              ? ListView(padding: const EdgeInsets.all(16), children: const [ShimmerCard(), ShimmerCard()])
              : _listings.isEmpty
                  ? EmptyState(icon: Icons.inventory_2_outlined, title: t("noListingsYet"))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _listings.length,
                        itemBuilder: (context, index) {
                          final listing = _listings[index];
                          final isActive = listing["isActive"] == true;
                          final priceInfo = listing["priceInfo"] ?? {};

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(listing["title"] ?? "", style: const TextStyle(fontWeight: FontWeight.w700)),
                                      ),
                                      Chip(
                                        label: Text(isActive ? t("active") : t("inactive"), style: const TextStyle(fontSize: 10.5)),
                                        backgroundColor: isActive ? Colors.green[100] : Colors.grey[300],
                                      ),
                                    ],
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Text("LKR ${priceInfo["amount"] ?? "-"} · ${priceInfo["unit"] ?? ""}", style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
                                  ),
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _editDialog(listing),
                                        icon: const Icon(Icons.edit_rounded, size: 15),
                                        label: Text(t("editListing"), style: const TextStyle(fontSize: 12)),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _toggleActive(listing),
                                        icon: Icon(isActive ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 15),
                                        label: Text(isActive ? t("deactivate") : t("activate"), style: const TextStyle(fontSize: 12)),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _delete(listing),
                                        icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.danger),
                                        label: Text(t("deleteListing"), style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }
}
