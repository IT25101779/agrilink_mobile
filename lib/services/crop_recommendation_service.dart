import '../models/milestone_model.dart';

enum CropCategory { vegetable, fruit, riceAndGrain, spice, legume, plantation }

extension CropCategoryLabel on CropCategory {
  String get label {
    switch (this) {
      case CropCategory.vegetable:
        return "Vegetables";
      case CropCategory.fruit:
        return "Fruits";
      case CropCategory.riceAndGrain:
        return "Rice & Grains";
      case CropCategory.spice:
        return "Spices";
      case CropCategory.legume:
        return "Legumes";
      case CropCategory.plantation:
        return "Plantation Crops";
    }
  }
}

class CropOption {
  final String name;
  final String nameSi;
  final CropCategory category;
  final int growthDurationDays;
  final List<String> suitableSoilTypes;
  final List<String> suitableClimateZones; // "wet", "intermediate", "dry"
  final String wikiImageTitle; // canonical Wikipedia article title used to fetch a real photo
  final List<int> bestPlantingMonths; // 1-12, aligned with Sri Lanka's Yala/Maha seasons

  const CropOption({
    required this.name,
    required this.nameSi,
    required this.category,
    required this.growthDurationDays,
    required this.suitableSoilTypes,
    required this.suitableClimateZones,
    required this.wikiImageTitle,
    required this.bestPlantingMonths,
  });
}

/// A comprehensive, Sri Lanka-focused crop catalogue spanning the major
/// categories smallholder farmers actually grow: vegetables, fruits, rice
/// & grains, spices, legumes, and plantation crops. Deliberately NOT a
/// "every crop in the world" database — a global catalogue would include
/// crops that can't grow in Sri Lanka's climate at all, which wouldn't
/// help anyone using this app. This runs fully offline (no network
/// required), matching the offline-first requirement.
class CropRecommendationService {
  static const List<CropOption> catalogue = [
    // ---- Rice & Grains ----
    CropOption(name: "Paddy (Rice)", nameSi: "වී", category: CropCategory.riceAndGrain, growthDurationDays: 105, suitableSoilTypes: ["clay", "loamy", "silty"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Rice", bestPlantingMonths: [10, 11, 4, 5]),
    CropOption(name: "Maize (Corn)", nameSi: "බඩඉරිඟු", category: CropCategory.riceAndGrain, growthDurationDays: 100, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["intermediate", "dry"], wikiImageTitle: "Maize", bestPlantingMonths: [9, 10, 11, 4, 5]),
    CropOption(name: "Kurakkan (Finger Millet)", nameSi: "කුරක්කන්", category: CropCategory.riceAndGrain, growthDurationDays: 90, suitableSoilTypes: ["loamy", "sandy", "silty"], suitableClimateZones: ["dry", "intermediate"], wikiImageTitle: "Finger millet", bestPlantingMonths: [9, 10]),
    CropOption(name: "Sorghum", nameSi: "සෝරගම්", category: CropCategory.riceAndGrain, growthDurationDays: 100, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["dry"], wikiImageTitle: "Sorghum", bestPlantingMonths: [9, 10, 4, 5]),

    // ---- Vegetables ----
    CropOption(name: "Tomato", nameSi: "තක්කාලි", category: CropCategory.vegetable, growthDurationDays: 75, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Tomato", bestPlantingMonths: [4, 5, 8, 9]),
    CropOption(name: "Chili", nameSi: "මිරිස්", category: CropCategory.vegetable, growthDurationDays: 90, suitableSoilTypes: ["loamy", "sandy", "silty"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Chili pepper", bestPlantingMonths: [4, 5, 9, 10]),
    CropOption(name: "Okra (Bandakka)", nameSi: "බණ්ඩක්කා", category: CropCategory.vegetable, growthDurationDays: 60, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Okra", bestPlantingMonths: [3, 4, 8, 9]),
    CropOption(name: "Brinjal (Eggplant)", nameSi: "වම්බටු", category: CropCategory.vegetable, growthDurationDays: 80, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Eggplant", bestPlantingMonths: [4, 5, 9, 10]),
    CropOption(name: "Cabbage", nameSi: "ගෝවා", category: CropCategory.vegetable, growthDurationDays: 70, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["wet"], wikiImageTitle: "Cabbage", bestPlantingMonths: [1, 2, 3, 8, 9]),
    CropOption(name: "Carrot", nameSi: "කැරට්", category: CropCategory.vegetable, growthDurationDays: 85, suitableSoilTypes: ["loamy", "sandy", "silty"], suitableClimateZones: ["wet"], wikiImageTitle: "Carrot", bestPlantingMonths: [1, 2, 3, 8, 9]),
    CropOption(name: "Beans (Bush)", nameSi: "බෝංචි", category: CropCategory.vegetable, growthDurationDays: 55, suitableSoilTypes: ["loamy", "silty"], suitableClimateZones: ["wet", "intermediate"], wikiImageTitle: "Common bean", bestPlantingMonths: [3, 4, 8, 9]),
    CropOption(name: "Cucumber", nameSi: "පිපිඤ්ඤා", category: CropCategory.vegetable, growthDurationDays: 55, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Cucumber", bestPlantingMonths: [3, 4, 8, 9]),
    CropOption(name: "Pumpkin", nameSi: "වට්ටක්කා", category: CropCategory.vegetable, growthDurationDays: 100, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["intermediate", "dry"], wikiImageTitle: "Pumpkin", bestPlantingMonths: [4, 5, 9, 10]),
    CropOption(name: "Bitter Gourd", nameSi: "කරවිල", category: CropCategory.vegetable, growthDurationDays: 65, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Momordica charantia", bestPlantingMonths: [3, 4, 8, 9]),
    CropOption(name: "Snake Gourd", nameSi: "පතෝල", category: CropCategory.vegetable, growthDurationDays: 70, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["wet", "intermediate"], wikiImageTitle: "Trichosanthes cucumerina", bestPlantingMonths: [3, 4, 8, 9]),
    CropOption(name: "Ash Plantain", nameSi: "අල කෙසෙල්", category: CropCategory.vegetable, growthDurationDays: 270, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["wet", "intermediate"], wikiImageTitle: "Cooking banana", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Beetroot", nameSi: "බීට්රූට්", category: CropCategory.vegetable, growthDurationDays: 70, suitableSoilTypes: ["loamy", "silty"], suitableClimateZones: ["wet"], wikiImageTitle: "Beetroot", bestPlantingMonths: [1, 2, 3, 8, 9]),
    CropOption(name: "Leeks", nameSi: "ලීක්ස්", category: CropCategory.vegetable, growthDurationDays: 90, suitableSoilTypes: ["loamy", "silty"], suitableClimateZones: ["wet"], wikiImageTitle: "Leek", bestPlantingMonths: [1, 2, 3]),
    CropOption(name: "Knol Khol", nameSi: "නෝල්කෝල්", category: CropCategory.vegetable, growthDurationDays: 60, suitableSoilTypes: ["loamy"], suitableClimateZones: ["wet"], wikiImageTitle: "Kohlrabi", bestPlantingMonths: [1, 2, 3]),
    CropOption(name: "Radish", nameSi: "රාබු", category: CropCategory.vegetable, growthDurationDays: 40, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["wet", "intermediate"], wikiImageTitle: "Radish", bestPlantingMonths: [1, 2, 3, 8, 9]),
    CropOption(name: "Winged Bean", nameSi: "දඹල", category: CropCategory.vegetable, growthDurationDays: 80, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["wet", "intermediate"], wikiImageTitle: "Winged bean", bestPlantingMonths: [4, 5, 9, 10]),
    CropOption(name: "Onion (Big/Red)", nameSi: "ලූනු", category: CropCategory.vegetable, growthDurationDays: 100, suitableSoilTypes: ["loamy", "sandy", "silty"], suitableClimateZones: ["dry", "intermediate"], wikiImageTitle: "Onion", bestPlantingMonths: [6, 7, 12, 1]),

    // ---- Fruits ----
    CropOption(name: "Banana", nameSi: "කෙසෙල්", category: CropCategory.fruit, growthDurationDays: 300, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Banana", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Papaya", nameSi: "පැපොල්", category: CropCategory.fruit, growthDurationDays: 270, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Papaya", bestPlantingMonths: [4, 5, 9, 10]),
    CropOption(name: "Pineapple", nameSi: "අන්නාසි", category: CropCategory.fruit, growthDurationDays: 450, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["wet", "intermediate"], wikiImageTitle: "Pineapple", bestPlantingMonths: [4, 5, 6]),
    CropOption(name: "Mango", nameSi: "අඹ", category: CropCategory.fruit, growthDurationDays: 1095, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["dry", "intermediate"], wikiImageTitle: "Mango", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Watermelon", nameSi: "කොමඩු", category: CropCategory.fruit, growthDurationDays: 85, suitableSoilTypes: ["sandy", "loamy"], suitableClimateZones: ["dry", "intermediate"], wikiImageTitle: "Watermelon", bestPlantingMonths: [1, 2, 6, 7]),
    CropOption(name: "Passion Fruit", nameSi: "පැෂන් ෆෘට්", category: CropCategory.fruit, growthDurationDays: 240, suitableSoilTypes: ["loamy"], suitableClimateZones: ["wet", "intermediate"], wikiImageTitle: "Passion fruit", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Guava", nameSi: "පේර", category: CropCategory.fruit, growthDurationDays: 365, suitableSoilTypes: ["loamy", "sandy", "clay"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Guava", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Rambutan", nameSi: "රඹුටන්", category: CropCategory.fruit, growthDurationDays: 1460, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["wet"], wikiImageTitle: "Rambutan", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Avocado", nameSi: "අලිගැට පේර", category: CropCategory.fruit, growthDurationDays: 1095, suitableSoilTypes: ["loamy"], suitableClimateZones: ["wet", "intermediate"], wikiImageTitle: "Avocado", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Wood Apple", nameSi: "දිවුල්", category: CropCategory.fruit, growthDurationDays: 1825, suitableSoilTypes: ["sandy", "loamy"], suitableClimateZones: ["dry", "intermediate"], wikiImageTitle: "Limonia acidissima", bestPlantingMonths: [4, 5]),
    CropOption(name: "Lime", nameSi: "දෙහි", category: CropCategory.fruit, growthDurationDays: 730, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Lime (fruit)", bestPlantingMonths: [4, 5, 10, 11]),

    // ---- Spices ----
    CropOption(name: "Black Pepper", nameSi: "ගම්මිරිස්", category: CropCategory.spice, growthDurationDays: 1095, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["wet"], wikiImageTitle: "Black pepper", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Cinnamon", nameSi: "කුරුඳු", category: CropCategory.spice, growthDurationDays: 730, suitableSoilTypes: ["sandy", "loamy"], suitableClimateZones: ["wet"], wikiImageTitle: "Cinnamon", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Cardamom", nameSi: "එනසාල්", category: CropCategory.spice, growthDurationDays: 1095, suitableSoilTypes: ["loamy"], suitableClimateZones: ["wet"], wikiImageTitle: "Cardamom", bestPlantingMonths: [4, 5]),
    CropOption(name: "Cloves", nameSi: "කරාබුනැටි", category: CropCategory.spice, growthDurationDays: 1825, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["wet"], wikiImageTitle: "Clove", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Nutmeg", nameSi: "සාදික්කා", category: CropCategory.spice, growthDurationDays: 2190, suitableSoilTypes: ["loamy"], suitableClimateZones: ["wet"], wikiImageTitle: "Nutmeg", bestPlantingMonths: [4, 5]),
    CropOption(name: "Ginger", nameSi: "ඉඟුරු", category: CropCategory.spice, growthDurationDays: 240, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["wet", "intermediate"], wikiImageTitle: "Ginger", bestPlantingMonths: [3, 4]),
    CropOption(name: "Turmeric", nameSi: "කහ", category: CropCategory.spice, growthDurationDays: 270, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Turmeric", bestPlantingMonths: [3, 4]),

    // ---- Legumes ----
    CropOption(name: "Green Gram (Mung Bean)", nameSi: "මුං ඇට", category: CropCategory.legume, growthDurationDays: 65, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["dry", "intermediate"], wikiImageTitle: "Mung bean", bestPlantingMonths: [2, 3, 8, 9]),
    CropOption(name: "Cowpea", nameSi: "මෑ ඇට", category: CropCategory.legume, growthDurationDays: 70, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["dry", "intermediate"], wikiImageTitle: "Cowpea", bestPlantingMonths: [2, 3, 8, 9]),
    CropOption(name: "Soybean", nameSi: "සෝයා බෝංචි", category: CropCategory.legume, growthDurationDays: 95, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["intermediate", "dry"], wikiImageTitle: "Soybean", bestPlantingMonths: [4, 5, 9, 10]),
    CropOption(name: "Groundnut (Peanut)", nameSi: "රටකජු", category: CropCategory.legume, growthDurationDays: 100, suitableSoilTypes: ["sandy", "loamy"], suitableClimateZones: ["dry", "intermediate"], wikiImageTitle: "Peanut", bestPlantingMonths: [2, 3, 8, 9]),
    CropOption(name: "Black Gram (Ulundu)", nameSi: "උළුඳු", category: CropCategory.legume, growthDurationDays: 75, suitableSoilTypes: ["loamy", "sandy"], suitableClimateZones: ["dry", "intermediate"], wikiImageTitle: "Vigna mungo", bestPlantingMonths: [2, 3, 8, 9]),

    // ---- Plantation Crops ----
    CropOption(name: "Tea", nameSi: "තේ", category: CropCategory.plantation, growthDurationDays: 1095, suitableSoilTypes: ["loamy"], suitableClimateZones: ["wet"], wikiImageTitle: "Tea plant", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Rubber", nameSi: "රබර්", category: CropCategory.plantation, growthDurationDays: 2190, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["wet"], wikiImageTitle: "Hevea brasiliensis", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Coconut", nameSi: "පොල්", category: CropCategory.plantation, growthDurationDays: 2190, suitableSoilTypes: ["sandy", "loamy"], suitableClimateZones: ["wet", "intermediate", "dry"], wikiImageTitle: "Coconut", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Coffee", nameSi: "කෝපි", category: CropCategory.plantation, growthDurationDays: 1095, suitableSoilTypes: ["loamy"], suitableClimateZones: ["wet", "intermediate"], wikiImageTitle: "Coffea", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Arecanut", nameSi: "පුවක්", category: CropCategory.plantation, growthDurationDays: 1825, suitableSoilTypes: ["loamy", "clay"], suitableClimateZones: ["wet"], wikiImageTitle: "Areca nut", bestPlantingMonths: [4, 5, 10, 11]),
    CropOption(name: "Cashew", nameSi: "කජු", category: CropCategory.plantation, growthDurationDays: 1095, suitableSoilTypes: ["sandy", "loamy"], suitableClimateZones: ["dry", "intermediate"], wikiImageTitle: "Cashew", bestPlantingMonths: [4, 5, 10, 11]),
  ];

  /// Filters by soil type AND climate zone together. If nothing matches
  /// both, falls back to soil-only matches so the farmer never sees an
  /// empty screen; falls back to the full catalogue as a last resort.
  static List<CropOption> recommend({
    required String soilType,
    required String climateZone,
    CropCategory? category,
  }) {
    Iterable<CropOption> pool = catalogue;
    if (category != null) {
      pool = pool.where((c) => c.category == category);
    }

    final fullMatch = pool.where((c) => c.suitableSoilTypes.contains(soilType) && c.suitableClimateZones.contains(climateZone)).toList();
    if (fullMatch.isNotEmpty) return fullMatch;

    final soilOnlyMatch = pool.where((c) => c.suitableSoilTypes.contains(soilType)).toList();
    if (soilOnlyMatch.isNotEmpty) return soilOnlyMatch;

    return pool.toList();
  }

  /// Looks up the Sinhala name for a crop given its English name (as stored
  /// in CultivationTimeline.cropType) — used by Timeline/Marketplace screens
  /// to show "Tomato (තක්කාලි)" without needing to store the Sinhala name
  /// separately in every record.
  static String? sinhalaNameFor(String englishName) {
    try {
      return catalogue.firstWhere((c) => c.name == englishName).nameSi;
    } catch (_) {
      return null;
    }
  }

  /// Looks up the Wikipedia article title for a crop given its English
  /// name — used to fetch its photo (CropThumbnail) outside the Navigator
  /// screen, e.g. on Timeline cards. Falls back to the English name itself
  /// if the crop isn't in the catalogue (still gives Wikipedia a reasonable
  /// query to try).
  static String wikiTitleFor(String englishName) {
    try {
      return catalogue.firstWhere((c) => c.name == englishName).wikiImageTitle;
    } catch (_) {
      return englishName;
    }
  }

  static List<CropOption> recommendForSoil(String soilType) {
    final matches = catalogue.where((c) => c.suitableSoilTypes.contains(soilType)).toList();
    return matches.isNotEmpty ? matches : catalogue;
  }

  /// Generates a day-by-day interactive milestone checklist for the chosen
  /// crop, evenly spaced across its growth cycle with standard farming
  /// activity stages. This is the "dynamic timeline" the farmer will tick
  /// off day by day, synced with weather alerts when online.
  static List<MilestoneModel> generateMilestoneTimeline(CropOption crop) {
    final duration = crop.growthDurationDays;
    final stages = <Map<String, dynamic>>[
      {"offset": 0.0, "title": "Land Preparation", "titleSi": "ඉඩම සකස් කිරීම", "description": "Plough and level the field. Clear weeds and debris.", "descriptionSi": "කුඹුර සී කර සමතලා කරන්න. වල් පැළෑටි හා අපද්‍රව්‍ය ඉවත් කරන්න."},
      {"offset": 0.02, "title": "Soil Testing & Fertilizer Base", "titleSi": "පස පරීක්ෂාව සහ පදනම් පොහොර", "description": "Apply base fertilizer / compost as per soil test.", "descriptionSi": "පස පරීක්ෂණයට අනුව පදනම් පොහොර / කොම්පෝස්ට් යොදන්න."},
      {"offset": 0.05, "title": "Sowing / Planting", "titleSi": "බීජ වැපිරීම / සිටුවීම", "description": "Plant seeds or seedlings for the crop.", "descriptionSi": "බෝගය සඳහා බීජ හෝ පැළ සිටුවන්න."},
      {"offset": 0.15, "title": "First Irrigation Check", "titleSi": "පළමු වාරි පරීක්ෂාව", "description": "Ensure adequate soil moisture; irrigate if dry.", "descriptionSi": "පසෙහි ප්‍රමාණවත් තෙතමනය තිබේදැයි පරීක්ෂා කරන්න; වියළි නම් වතුර දෙන්න."},
      {"offset": 0.25, "title": "First Weeding", "titleSi": "පළමු වල් නෙළීම", "description": "Remove weeds competing for nutrients.", "descriptionSi": "පෝෂක සඳහා තරඟ කරන වල් පැළෑටි ඉවත් කරන්න."},
      {"offset": 0.35, "title": "First Fertilizer Top-up", "titleSi": "පළමු පොහොර යෙදීම", "description": "Apply top-dressing fertilizer.", "descriptionSi": "වර්ධන පොහොර යොදන්න."},
      {"offset": 0.45, "title": "Pest & Disease Inspection", "titleSi": "පළිබෝධ හා රෝග පරීක්ෂාව", "description": "Scan leaves for early signs of disease. Use the Disease Scanner if spots appear.", "descriptionSi": "රෝග ලක්ෂණ සඳහා කොළ පරීක්ෂා කරන්න. පැල්ලම් පෙනේ නම් රෝග පරීක්ෂකය භාවිත කරන්න."},
      {"offset": 0.55, "title": "Second Weeding", "titleSi": "දෙවන වල් නෙළීම", "description": "Clear regrowth of weeds.", "descriptionSi": "යළි වැඩුණු වල් පැළෑටි ඉවත් කරන්න."},
      {"offset": 0.65, "title": "Second Fertilizer Top-up", "titleSi": "දෙවන පොහොර යෙදීම", "description": "Apply second round of fertilizer for flowering/fruiting stage.", "descriptionSi": "මල් හා ගෙඩි අවධිය සඳහා දෙවන පොහොර වටය යොදන්න."},
      {"offset": 0.75, "title": "Flowering / Fruit Set Monitoring", "titleSi": "මල් හා ගෙඩි ගැසීම නිරීක්ෂණය", "description": "Monitor flowering and early fruit development.", "descriptionSi": "මල් හැදීම හා මුල් අවධියේ ගෙඩි වර්ධනය නිරීක්ෂණය කරන්න."},
      {"offset": 0.88, "title": "Pre-Harvest Pest Check", "titleSi": "අස්වනු නෙළීමට පෙර පළිබෝධ පරීක්ෂාව", "description": "Final pest and disease inspection before harvest.", "descriptionSi": "අස්වනු නෙළීමට පෙර අවසාන පළිබෝධ හා රෝග පරීක්ෂාව."},
      {"offset": 0.97, "title": "Harvest Readiness Check", "titleSi": "අස්වනු සූදානම් බව පරීක්ෂාව", "description": "Confirm maturity indicators before harvesting.", "descriptionSi": "නෙළීමට පෙර පරිණත බව තහවුරු කරන්න."},
      {"offset": 1.0, "title": "Harvest", "titleSi": "අස්වනු නෙළීම", "description": "Harvest the crop and prepare for market listing.", "descriptionSi": "බෝගය නෙළා වෙළඳපොළට සකස් කරන්න."},
    ];

    return stages.map((stage) {
      final day = (duration * (stage["offset"] as double)).round();
      return MilestoneModel(
        day: day,
        title: stage["title"] as String,
        titleSi: stage["titleSi"] as String,
        description: stage["description"] as String,
        descriptionSi: stage["descriptionSi"] as String,
      );
    }).toList()
      ..sort((a, b) => a.day.compareTo(b.day));
  }
}
