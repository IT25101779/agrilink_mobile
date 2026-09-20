import '../widgets/ad_banner.dart';
import '../widgets/delivery_check_sheet.dart';
import '../widgets/smooth_route.dart';
import '../localization/tr.dart';
import 'return_trips_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  Future<void> _requestCargoSpace(Map<String, dynamic> lorry) async {
    final weightController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Request space on ${lorry["vehicleRegistrationNo"]}"),
        content: TextField(
          controller: weightController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: tr("Weight to send (kg)", "යැවිය යුතු බර (කි.ග්‍රෑ.)", "அனுப்ப வேண்டிய எடை (கி.கி.)"),
            helperText: "Available: ${lorry["remainingCapacityKg"]}kg",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr("Cancel", "අවලංගු", "ரத்து செய்"))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Request", "ඉල්ලන්න", "கோரு"))),
        ],
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
    );

    if (!mounted) return;

    if (result["success"] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Cargo space requested! The driver will confirm shortly.", "භාණ්ඩ ඉඩ ඉල්ලා ඇත! රියදුරු ඉක්මනින් තහවුරු කරනු ඇත.", "சரக்கு இடம் கோரப்பட்டது! ஓட்டுநர் விரைவில் உறுதிப்படுத்துவார்."))),
      );
      _searchNearbyLorries();
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
