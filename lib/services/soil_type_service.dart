/// Bilingual (English + Sinhala) labels for soil types.
class SoilTypeService {
  static const List<String> allTypes = ["loamy", "clay", "sandy", "silty", "peaty", "chalky"];

  static const Map<String, String> _sinhalaLabels = {
    "loamy": "ලෝම පස්",
    "clay": "මැටි පස්",
    "sandy": "වැලි පස්",
    "silty": "රොන් පස්",
    "peaty": "පීට් පස්",
    "chalky": "හුණු පස්",
  };

  static String englishLabel(String key) => key[0].toUpperCase() + key.substring(1);

  static String sinhalaLabel(String key) => _sinhalaLabels[key] ?? key;

  static String bilingualLabel(String key) => "${englishLabel(key)} (${sinhalaLabel(key)})";
}
