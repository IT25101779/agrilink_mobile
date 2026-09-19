/// A single map pin — deliberately generic (not tied to LocalSupplier or
/// CommunityListing's exact JSON shape) so MapViewScreen can be reused by
/// both the Suppliers screen and the Community Marketplace screen, each
/// mapping their own API response into this shape before pushing the map.
class MapPinData {
  final String name;
  final double latitude;
  final double longitude;
  final String? phone;
  final String? subtitle;

  const MapPinData({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.phone,
    this.subtitle,
  });
}
