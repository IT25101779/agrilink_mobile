import '../widgets/session_guard.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../localization/app_locale.dart';
import 'login_screen.dart';
import 'driver_trips_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/ad_banner.dart';
import '../widgets/smooth_route.dart';
import '../localization/tr.dart';

const List<String> _destinationHubs = [
  "Dambulla",
  "Colombo_Manning_Market",
  "Pettah",
  "Kandy",
  "Jaffna",
  "Other",
];

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _vehicleRegController = TextEditingController();
  final _capacityController = TextEditingController();
  String _destinationHub = _destinationHubs.first;

  Map<String, dynamic>? _myLorry;
  bool _isTrackingActive = false;
  bool _isLoading = true;
  bool _isSaving = false;
  Timer? _locationPingTimer;
  String _userName = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _locationPingTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    _userName = await AuthService.getUserName() ?? "";
    await _loadMyLorry();
    setState(() => _isLoading = false);
  }

  Future<void> _loadMyLorry() async {
    final driverId = await AuthService.getUserId();
    if (driverId == null) return;
    final result = await ApiService.getMyLorry(driverId);
    if (result["success"] == true && result["data"] != null) {
      setState(() {
        _myLorry = result["data"];
        _isTrackingActive = _myLorry?["isTrackingActive"] ?? false;
        _vehicleRegController.text = _myLorry?["vehicleRegistrationNo"] ?? "";
        _capacityController.text = "${_myLorry?["totalCapacityKg"] ?? ""}";
        _destinationHub = _myLorry?["destinationHub"] ?? _destinationHubs.first;
      });
      if (_isTrackingActive) _startLocationPings();
    }
  }

  Future<Position?> _getPosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  Future<void> _declareStatus() async {
    if (_vehicleRegController.text.trim().isEmpty || _capacityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("Please enter vehicle registration and capacity.", "කරුණාකර වාහන ලියාපදිංචි අංකය සහ ධාරිතාව ඇතුළත් කරන්න.", "வாகனப் பதிவு எண்ணையும் திறனையும் உள்ளிடுங்கள்."))),
      );
      return;
    }

    setState(() => _isSaving = true);
    final driverId = await AuthService.getUserId() ?? "";
    final position = await _getPosition();
    final latitude = position?.latitude ?? 7.2906;
    final longitude = position?.longitude ?? 80.6337;

    final result = await ApiService.upsertLorryStatus(
      driverId: driverId,
      vehicleRegistrationNo: _vehicleRegController.text.trim(),
      totalCapacityKg: double.parse(_capacityController.text),
      destinationHub: _destinationHub,
      latitude: latitude,
      longitude: longitude,
      isTrackingActive: true,
    );

    setState(() => _isSaving = false);

    if (result["success"] == true) {
      setState(() {
        _myLorry = result["data"];
        _isTrackingActive = true;
      });
      _startLocationPings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("Status declared. You are now visible to nearby farmers.", "තත්ත්වය ප්‍රකාශ කළා. ඔබ දැන් අවට ගොවීන්ට පෙනේ.", "நிலை அறிவிக்கப்பட்டது. நீங்கள் இப்போது அருகிலுள்ள விவசாயிகளுக்குத் தெரிவீர்கள்."))),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result["message"] ?? "Failed to declare status.")),
      );
    }
  }

  void _startLocationPings() {
    _locationPingTimer?.cancel();
    // Pings every 30 seconds while tracking is active — simulates the
    // continuous GPS stream a real driver app would send in the background.
    _locationPingTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (_myLorry == null || !_isTrackingActive) return;
      final position = await _getPosition();
      if (position == null) return;
      await ApiService.updateLorryLocation(
        lorryId: _myLorry!["_id"],
        latitude: position.latitude,
        longitude: position.longitude,
      );
    });
  }

  Future<void> _toggleTracking(bool value) async {
    if (_myLorry == null) return;
    setState(() => _isTrackingActive = value);
    await ApiService.toggleLorryTracking(lorryId: _myLorry!["_id"], isTrackingActive: value);
    if (value) {
      _startLocationPings();
    } else {
      _locationPingTimer?.cancel();
    }
  }

  Future<void> _respondToBooking(String bookingId, String status) async {
    if (_myLorry == null) return;
    final result = await ApiService.updateCargoBooking(
      lorryId: _myLorry!["_id"],
      bookingId: bookingId,
      status: status,
    );
    if (result["success"] == true) {
      setState(() => _myLorry = result["data"]);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result["message"] ?? "Update failed.")));
    }
  }

  Future<void> _logout() async {
    _locationPingTimer?.cancel();
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bookings = (_myLorry?["cargoBookings"] as List?) ?? [];
    final pendingBookings = bookings.where((b) => b["status"] == "requested").toList();
    final activeBookings = bookings.where((b) => ["confirmed", "picked_up"].contains(b["status"])).toList();

    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return SessionGuard(child: Scaffold(
      appBar: AppBar(
        title: Text(tr("Driver Dashboard", "රියදුරු උපකරණ පුවරුව", "ஓட்டுநர் முகப்புப் பலகை")),
                actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: Text(_userName, style: const TextStyle(fontSize: 13))),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdBanner(placement: "driver"),
                  Row(children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, SmoothRoute(page: const DriverTripsScreen())), icon: const Icon(Icons.add_road_rounded), label: Text(tr("Return trips", "ආපසු ගමන්", "திரும்பும் பயணங்கள்")))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(onPressed: () => Navigator.push(context, SmoothRoute(page: const EditProfileScreen())), icon: const Icon(Icons.person_rounded), label: Text(tr("My profile", "මගේ පැතිකඩ", "என் சுயவிவரம்")))),
                  ]),
                  const SizedBox(height: 14),
                  Text(t("tripStatus"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _vehicleRegController,
                    decoration: InputDecoration(labelText: tr("Vehicle registration no.", "වාහන ලියාපදිංචි අංකය", "வாகனப் பதிவு எண்"), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: tr("Total capacity (kg)", "මුළු ධාරිතාව (කි.ග්‍රෑ.)", "மொத்தத் திறன் (கி.கி.)"), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _destinationHub,
                    decoration: InputDecoration(labelText: tr("Target destination hub", "ඉලක්කගත ගමනාන්ත මධ්‍යස්ථානය", "இலக்கு சேருமிட மையம்"), border: OutlineInputBorder()),
                    items: _destinationHubs
                        .map((hub) => DropdownMenuItem(value: hub, child: Text(hub.replaceAll("_", " "))))
                        .toList(),
                    onChanged: (v) => setState(() => _destinationHub = v ?? _destinationHubs.first),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _declareStatus,
                      style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(_myLorry == null ? t("startTrip") : t("updateTripStatus")),
                    ),
                  ),
                  if (_myLorry != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFFEFF7F1), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.gps_fixed, color: Color(0xFF0B5D3B)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t("liveTracking"))),
                          Switch(
                            value: _isTrackingActive,
                            activeColor: const Color(0xFF0B5D3B),
                            onChanged: _toggleTracking,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Remaining capacity: ${_myLorry!["remainingCapacityKg"]} / ${_myLorry!["totalCapacityKg"]} kg",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text("${t("pendingRequests")} (${pendingBookings.length})",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (pendingBookings.isEmpty)
                    Text(t("noNewRequests"), style: const TextStyle(color: Colors.grey))
                  else
                    ...pendingBookings.map((b) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text("${b["farmer"]?["fullName"] ?? "Farmer"} — ${b["weightKg"]}kg"),
                            subtitle: Text(b["farmer"]?["phone"] ?? ""),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () => _respondToBooking(b["_id"], "confirmed"),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _respondToBooking(b["_id"], "cancelled"),
                                ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 20),
                  Text("${t("activeBookings")} (${activeBookings.length})",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (activeBookings.isEmpty)
                    Text(tr("No active cargo on board.", "දැනට ප්‍රවාහනය කරන භාණ්ඩ නැත.", "தற்போது ஏற்றப்பட்ட சரக்கு இல்லை."), style: TextStyle(color: Colors.grey))
                  else
                    ...activeBookings.map((b) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text("${b["farmer"]?["fullName"] ?? "Farmer"} — ${b["weightKg"]}kg"),
                            subtitle: Text("Status: ${b["status"]}"),
                            trailing: b["status"] == "confirmed"
                                ? TextButton(
                                    onPressed: () => _respondToBooking(b["_id"], "picked_up"),
                                    child: Text(tr("Mark Picked Up", "රැගෙන ගියා ලෙස සලකුණු කරන්න", "எடுத்துச் சென்றதாகக் குறி")),
                                  )
                                : TextButton(
                                    onPressed: () => _respondToBooking(b["_id"], "delivered"),
                                    child: Text(tr("Mark Delivered", "බෙදා හැරියා ලෙස සලකුණු කරන්න", "வழங்கப்பட்டதாகக் குறி")),
                                  ),
                          ),
                        )),
                ],
              ),
            ),
    ));
      },
    );
  }
}
