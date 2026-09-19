import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/map_pin_data.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';

/// Generic map view: shows every pin passed in, and tapping one shows a
/// bottom card with Call and Get Directions buttons. Reused by both the
/// Suppliers screen (business listings) and the Community Marketplace
/// screen (farmer-posted rentals/seeds) — neither of those had a map view
/// before, only a plain list.
class MapViewScreen extends StatefulWidget {
  final String title;
  final List<MapPinData> pins;
  final double initialLatitude;
  final double initialLongitude;

  const MapViewScreen({
    super.key,
    required this.title,
    required this.pins,
    this.initialLatitude = 7.2906,
    this.initialLongitude = 80.6337,
  });

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  MapPinData? _selected;

  Set<Marker> _buildMarkers() {
    return widget.pins.map((pin) {
      return Marker(
        markerId: MarkerId("${pin.name}_${pin.latitude}_${pin.longitude}"),
        position: LatLng(pin.latitude, pin.longitude),
        infoWindow: InfoWindow(title: pin.name, snippet: pin.subtitle),
        onTap: () => setState(() => _selected = pin),
      );
    }).toSet();
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _directions(MapPinData pin) async {
    final uri = Uri.parse("https://www.google.com/maps/dir/?api=1&destination=${pin.latitude},${pin.longitude}");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        return Scaffold(
          appBar: AppBar(title: Text(widget.title)),
          body: Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.initialLatitude, widget.initialLongitude),
                  zoom: 11,
                ),
                markers: _buildMarkers(),
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onTap: (_) => setState(() => _selected = null),
              ),
              if (widget.pins.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Text(t("noCommunityListingsFound"), style: const TextStyle(color: AppColors.inkMuted)),
                  ),
                ),
              if (_selected != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selected!.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          if (_selected!.subtitle != null && _selected!.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(_selected!.subtitle!, style: const TextStyle(fontSize: 12.5, color: AppColors.inkMuted)),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (_selected!.phone != null)
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _call(_selected!.phone!),
                                    icon: const Icon(Icons.call_rounded, size: 16),
                                    label: Text(t("call")),
                                  ),
                                ),
                              if (_selected!.phone != null) const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _directions(_selected!),
                                  icon: const Icon(Icons.directions_rounded, size: 16),
                                  label: Text(t("getDirections")),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
