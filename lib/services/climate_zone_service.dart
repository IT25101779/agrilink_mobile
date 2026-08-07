/// Sri Lanka's 25 districts mapped to their dominant agro-climatic zone.
/// This is a simplification (some districts straddle zones) but reflects
/// the standard Wet/Intermediate/Dry Zone classification used in Sri
/// Lankan agricultural extension guidance.
class ClimateZoneService {
  static const Map<String, String> _districtToZone = {
    "Colombo": "wet",
    "Gampaha": "wet",
    "Kalutara": "wet",
    "Kandy": "wet",
    "Matale": "intermediate",
    "Nuwara Eliya": "wet",
    "Galle": "wet",
    "Matara": "wet",
    "Hambantota": "dry",
    "Jaffna": "dry",
    "Kilinochchi": "dry",
    "Mannar": "dry",
    "Vavuniya": "dry",
    "Mullaitivu": "dry",
    "Batticaloa": "dry",
    "Ampara": "dry",
    "Trincomalee": "dry",
    "Kurunegala": "intermediate",
    "Puttalam": "dry",
    "Anuradhapura": "dry",
    "Polonnaruwa": "dry",
    "Badulla": "intermediate",
    "Monaragala": "dry",
    "Ratnapura": "wet",
    "Kegalle": "wet",
  };

  static const Map<String, String> zoneLabels = {
    "wet": "Wet Zone",
    "intermediate": "Intermediate Zone",
    "dry": "Dry Zone",
  };

  /// Case-insensitive, trims whitespace, falls back to "intermediate"
  /// (the most agriculturally flexible zone) if the district isn't
  /// recognized — e.g. typos or a farmer entering something unexpected.
  static String zoneForDistrict(String? district) {
    if (district == null || district.trim().isEmpty) return "intermediate";
    final normalized = district.trim();
    final match = _districtToZone.entries.firstWhere(
      (e) => e.key.toLowerCase() == normalized.toLowerCase(),
      orElse: () => const MapEntry("", "intermediate"),
    );
    return match.value;
  }

  static List<String> get allDistricts => _districtToZone.keys.toList()..sort();
}
