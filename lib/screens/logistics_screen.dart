import '../widgets/ad_banner.dart';
import '../widgets/delivery_check_sheet.dart';
import '../widgets/smooth_route.dart';
import '../localization/tr.dart';
import 'return_trips_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../localization/app_locale.dart';
import '../widgets/shimmer_loading.dart';
import '../localization/tr.dart';

const List<String> _destinationHubs = [
  "Any",
  "Dambulla",
  "Colombo_Manning_Market",
  "Pettah",
  "Kandy",
  "Jaffna",
  "Other",
];

class LogisticsScreen extends StatefulWidget {
  const LogisticsScreen({super.key});

  @override
  State<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends State<LogisticsScreen> {
  String _destinationFilter = "Any";
  List<dynamic> _lorries = [];
  bool _isLoading = false;
  String? _statusMessage;

  List<dynamic> _myBookings = [];
  bool _isLoadingBookings = false;

  Future<void> _callNumber(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _searchNearbyLorries() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
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
    } catch (_) {
      // fall back below
    }

    final latitude = position?.latitude ?? 7.2906;
    final longitude = position?.longitude ?? 80.6337;

    final result = await ApiService.getNearbyLorries(
      latitude: latitude,
      longitude: longitude,
      radiusKm: 50,
      destinationHub: _destinationFilter == "Any" ? null : _destinationFilter,
    );

    setState(() {
      _isLoading = false;
      if (result["success"] == true) {
        _lorries = result["data"] as List;
        if (_lorries.isEmpty) _statusMessage = AppLocale.instance.t("noTrucksFound");
      } else {
        _lorries = [];
        _statusMessage = result["message"] ?? "Could not search for trucks.";
      }
    });
  }

  Future<void> _loadMyBookings() async {
    setState(() => _isLoadingBookings = true);
    final result = await ApiService.getMyCargoBookings();
    setState(() {
      _isLoadingBookings = false;
      if (result["success"] == true) _myBookings = result["data"] as List;
    });
  }

  Future<void> _requestCargoSpace(Map<String, dynamic> lorry) async {
    final weightController = TextEditingController();
    final cropController = TextEditingController();
    List<dynamic> shops = [];
    String? selectedShopId;
    int? rentLkr;
    bool loadingShops = true;

    // Load the shop directory for this lorry's destination market, and
    // pre-select the market's featured/most-chosen shop (e.g. Kandy's
    // No. 166, Samansiri Holdings) if there is one.
    final shopResult = await ApiService.getMarketShops(lorry["destinationHub"] ?? "");
    if (shopResult["success"] == true) {
      shops = shopResult["data"] as List;
      final featured = shops.where((s) => s["isFeatured"] == true).toList();
      selectedShopId = (featured.isNotEmpty ? featured.first : (shops.isNotEmpty ? shops.first : null))?["_id"];
    }
    loadingShops = false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> recalcRent(String text) async {
            final w = double.tryParse(text);
            if (w == null || w <= 0) {
              setDialogState(() => rentLkr = null);
              return;
            }
            final quote = await ApiService.getLorryRentQuote(w);
            if (quote["success"] == true) {
              setDialogState(() => rentLkr = quote["data"]["rentLkr"] as int);
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text("${tr("Book space on", "ඉඩ වෙන් කරන්න", "இடம் பதிவு செய்")} ${lorry["vehicleRegistrationNo"]}"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: cropController,
                    decoration: InputDecoration(labelText: tr("Crop type", "බෝගය", "பயிர் வகை")),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: weightController,
                    keyboardType: TextInputType.number,
                    onChanged: recalcRent,
                    decoration: InputDecoration(
                      labelText: tr("Weight to send (kg)", "යැවිය යුතු බර (කි.ග්‍රෑ.)", "அனுப்ப வேண்டிய எடை (கி.கி.)"),
                      helperText: "Available: ${lorry["remainingCapacityKg"]}kg",
                    ),
                  ),
                  if (rentLkr != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        "${tr("Estimated truck rent", "ඇස්තමේන්තුගත කුලිය", "மதிப்பிடப்பட்ட வாடகை")}: LKR $rentLkr",
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0B5D3B)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Text(tr("Which shop should we deliver to?", "බෙදා දිය යුතු කඩය කුමක්ද?", "எந்தக் கடைக்கு வழங்க வேண்டும்?"),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  if (loadingShops)
                    const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2))
                  else if (shops.isEmpty)
                    Text(tr("No shop list yet for this market.", "මෙම වෙළඳපොළට තවම කඩ ලැයිස්තුවක් නැත.", "இந்த சந்தைக்கு இன்னும் கடை பட்டியல் இல்லை."),
                        style: const TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    DropdownButtonFormField<String>(
                      value: selectedShopId,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: shops
                          .map<DropdownMenuItem<String>>((s) => DropdownMenuItem(
                                value: s["_id"] as String,
                                child: Text(
                                  "No. ${s["shopNumber"]} — ${s["name"]}${s["isFeatured"] == true ? "  ★" : ""}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedShopId = v),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    tr(
                      "No online booking is placed yet — the driver must confirm by phone before this is final.",
                      "තවම මාර්ගගත වෙන්කිරීමක් සිදු නොවේ — අවසන් වීමට පෙර රියදුරු දුරකථනයෙන් තහවුරු කළ යුතුය.",
                      "இன்னும் ஆன்லைன் முன்பதிவு செய்யப்படவில்லை — உறுதி செய்வதற்கு முன் ஓட்டுநர் தொலைபேசியில் உறுதிப்படுத்த வேண்டும்.",
                    ),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr("Cancel", "අවලංගු", "ரத்து செய்"))),
              ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Request", "ඉල්ලන්න", "கோரு"))),
            ],
          );
        },
      ),
    );

    if (confirmed != true) return;
    final weight = double.tryParse(weightController.text);
    if (weight == null || weight <= 0) return;

    final farmerId = await AuthService.getUserId() ?? "";
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (_) {}

    final result = await ApiService.requestCargoSpace(
      lorryId: lorry["_id"],
      farmerId: farmerId,
      weightKg: weight,
      latitude: position?.latitude ?? 7.2906,
      longitude: position?.longitude ?? 80.6337,
      cropType: cropController.text.trim().isEmpty ? null : cropController.text.trim(),
      shopId: selectedShopId,
    );

    if (!mounted) return;

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Cargo space requested! The driver will confirm shortly.", "භාණ්ඩ ඉඩ ඉල්ලා ඇත! රියදුරු ඉක්මනින් තහවුරු කරනු ඇත.", "சரக்கு இடம் கோரப்பட்டது! ஓட்டுநர் விரைவில் உறுதிப்படுத்துவார்."))),
      );
      _searchNearbyLorries();
      _loadMyBookings();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Request failed.")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _searchNearbyLorries();
    _loadMyBookings();
  }

  Widget _buildMyBookings() {
    if (_isLoadingBookings) return const SizedBox.shrink();
    if (_myBookings.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr("Your truck requests", "ඔබේ ලොරි ඉල්ලීම්", "உங்கள் லாரி கோரிக்கைகள்"), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
          ..._myBookings.map((b) {
            final status = b["status"] as String? ?? "requested";
            final isConfirmed = status == "confirmed" || status == "picked_up" || status == "delivered";
            final driverPhone = b["driver"]?["phone"] as String?;
            final shop = b["shop"];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  isConfirmed ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                  color: isConfirmed ? const Color(0xFF0B5D3B) : Colors.orange,
                ),
                title: Text("${b["cropType"] ?? ""} · ${b["weightKg"]}kg → ${(b["destinationHub"] ?? "").toString().replaceAll("_", " ")}"),
                subtitle: Text(
                  [
                    if (b["calculatedRentLkr"] != null) "${tr("Rent", "කුලිය", "வாடகை")}: LKR ${b["calculatedRentLkr"]}",
                    if (shop != null) "${tr("Shop", "කඩය", "கடை")}: No. ${shop["shopNumber"]} ${shop["name"]}",
                    "${tr("Status", "තත්ත්වය", "நிலை")}: $status",
                  ].join("\n"),
                ),
                isThreeLine: true,
                trailing: isConfirmed && driverPhone != null
                    ? IconButton(
                        icon: const Icon(Icons.call_rounded, color: Color(0xFF0B5D3B)),
                        tooltip: tr("Call driver", "රියදුරුට කතා කරන්න", "ஓட்டுநரை அழைக்கவும்"),
                        onPressed: () => _callNumber(driverPhone),
                      )
                    : null,
              ),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) => Column(
      children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 0), child: AdBanner(placement: "logistics")),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, SmoothRoute(page: const ReturnTripsScreen())), icon: const Icon(Icons.local_shipping_rounded, size: 18), label: Text(tr("Return-load deals", "ආපසු ගමන් දීමනා", "திரும்பும் லாரி சலுகைகள்"), style: const TextStyle(fontSize: 12)))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(onPressed: () => showDeliveryCheckSheet(context), icon: const Icon(Icons.ac_unit_rounded, size: 18), label: Text(tr("Freshness check", "නැවුම්බව පරීක්ෂාව", "புத்துணர்ச்சிச் சோதனை"), style: const TextStyle(fontSize: 12)))),
          ]),
        ),
        _buildMyBookings(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _destinationFilter,
                  decoration: InputDecoration(labelText: AppLocale.instance.t("destinationHub"), border: const OutlineInputBorder()),
                  items: _destinationHubs
                      .map((hub) => DropdownMenuItem(value: hub, child: Text(hub.replaceAll("_", " "))))
                      .toList(),
                  onChanged: (v) {
                    setState(() => _destinationFilter = v ?? "Any");
                    _searchNearbyLorries();
                  },
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed: _searchNearbyLorries,
                icon: const Icon(Icons.refresh, color: Color(0xFF0B5D3B)),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [ShimmerCard(), ShimmerCard(), ShimmerCard()],
                )
              : _lorries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _statusMessage ?? "No trucks found.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _lorries.length,
                      itemBuilder: (context, index) {
                        final lorry = _lorries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF0B5D3B),
                              child: Icon(Icons.local_shipping, color: Colors.white, size: 20),
                            ),
                            title: Text(lorry["vehicleRegistrationNo"] ?? "Truck"),
                            subtitle: Text(
                              "${(lorry["destinationHub"] ?? "").toString().replaceAll("_", " ")} · "
                              "${lorry["remainingCapacityKg"]}kg available\n"
                              "Driver: ${lorry["driver"]?["fullName"] ?? "Unknown"}",
                            ),
                            isThreeLine: true,
                            trailing: ElevatedButton(
                              onPressed: () => _requestCargoSpace(lorry),

                              child: Text(AppLocale.instance.t("requestSpace")),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    ),
    );
  }
}
