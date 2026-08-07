import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AgriLink AI's localization system. Deliberately lightweight (a plain
/// key -> {en, si} map) rather than Flutter's full intl/.arb toolchain,
/// so it's easy for a solo dev to extend: just add a new key to
/// [_translations] and call AppLocale.t('yourKey') anywhere in the UI.
///
/// [AppLocale.instance] is a singleton ChangeNotifier — wrap the app in a
/// ListenableBuilder listening to it, and every screen using AppLocale.t()
/// rebuilds instantly when the farmer switches language.
class AppLocale extends ChangeNotifier {
  static final AppLocale instance = AppLocale._internal();
  AppLocale._internal();

  String _languageCode = "en"; // "en" or "si"
  String get languageCode => _languageCode;

  static const _prefsKey = "app_language_code";

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_prefsKey) ?? "en";
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }

  /// Speech recognition / TTS locale ID for the current language.
  String get speechLocaleId => _languageCode == "si" ? "si-LK" : "en-US";

  /// Translate a key to the current language, falling back to English,
  /// then to the key itself if nothing is found (so missing translations
  /// never crash the UI — they just show the English/key text instead).
  String t(String key) {
    final entry = _translations[key];
    if (entry == null) return key;
    return entry[_languageCode] ?? entry["en"] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    // Brand name — kept identical across languages, same way most Sri
    // Lankan brand names stay in their original script regardless of
    // interface language.
    "appName": {"en": "ගොවි Tech", "si": "ගොවි Tech"},
    "tagline": {"en": "Smart Agriculture Ecosystem", "si": "ස්මාර්ට් කෘෂිකර්ම පද්ධතිය"},
    "signInToContinue": {"en": "Sign in to continue", "si": "ඉදිරියට යාමට පිවිසෙන්න"},

    "email": {"en": "Email", "si": "විද්‍යුත් තැපෑල"},
    "password": {"en": "Password", "si": "මුරපදය"},
    "forgotPassword": {"en": "Forgot password?", "si": "මුරපදය අමතකද?"},
    "login": {"en": "Login", "si": "පිවිසෙන්න"},
    "dontHaveAccount": {"en": "Don't have an account? Register", "si": "ගිණුමක් නැද්ද? ලියාපදිංචි වන්න"},
    "createAccount": {"en": "Create Account", "si": "ගිණුමක් සාදන්න"},
    "fullName": {"en": "Full name", "si": "සම්පූර්ණ නම"},
    "phoneNumber": {"en": "Phone number", "si": "දුරකථන අංකය"},
    "district": {"en": "District", "si": "දිස්ත්‍රික්කය"},
    "iAmA": {"en": "I am a…", "si": "මම වන්නේ…"},
    "farmer": {"en": "Farmer", "si": "ගොවියා"},
    "truckDriver": {"en": "Truck Driver", "si": "රථ රියදුරු"},
    "vehicleRegNo": {"en": "Vehicle registration number", "si": "වාහන ලියාපදිංචි අංකය"},
    "vehicleCapacity": {"en": "Vehicle capacity (kg)", "si": "වාහන ධාරිතාව (kg)"},
    "passwordMin": {"en": "Password (min 6 characters)", "si": "මුරපදය (අවම අක්ෂර 6ක්)"},

    "myTimelines": {"en": "My Timelines", "si": "මගේ වගා කාලසටහන්"},
    "cropNavigator": {"en": "Crop Navigator", "si": "බෝග මාර්ගෝපදේශකය"},
    "diseaseScanner": {"en": "Disease Scanner", "si": "රෝග පරීක්ෂකය"},
    "logistics": {"en": "Logistics", "si": "ප්‍රවාහනය"},
    "marketplace": {"en": "Marketplace", "si": "වෙළඳපොළ"},
    "timelines": {"en": "Timelines", "si": "කාලසටහන්"},
    "navigator": {"en": "Navigator", "si": "මාර්ගෝපදේශකය"},
    "scanner": {"en": "Scanner", "si": "පරීක්ෂකය"},
    "market": {"en": "Market", "si": "වෙළඳපොළ"},

    "tellUsAboutLand": {"en": "Tell us about your land", "si": "ඔබේ ඉඩම ගැන අපට කියන්න"},
    "landSizeAcres": {"en": "Land size (acres)", "si": "ඉඩම් ප්‍රමාණය (අක්කර)"},
    "soilType": {"en": "Soil type", "si": "පස් වර්ගය"},
    "getCropRecommendations": {"en": "Get Crop Recommendations", "si": "බෝග නිර්දේශ ලබාගන්න"},
    "recommendedCrops": {"en": "Recommended crops for your soil:", "si": "ඔබේ පසට නිර්දේශිත බෝග:"},
    "growthCycle": {"en": "Growth cycle", "si": "වර්ධන චක්‍රය"},
    "days": {"en": "days", "si": "දින"},
    "startTimeline": {"en": "Start Timeline", "si": "කාලසටහන ආරම්භ කරන්න"},

    "noActiveTimelines": {"en": "No active timelines yet.", "si": "තවම ක්‍රියාත්මක කාලසටහන් නැත."},
    "goToNavigatorHint": {"en": "Go to the Navigator tab to start one!", "si": "එකක් ආරම්භ කිරීමට Navigator ටැබයට යන්න!"},
    "worksOffline": {
      "en": "Works fully offline. Syncs automatically when you're back online.",
      "si": "සම්පූර්ණයෙන්ම නොබැඳිව ක්‍රියා කරයි. නැවත සම්බන්ධ වූ විට ස්වයංක්‍රීයව සමමුහුර්ත වේ.",
    },
    "syncNow": {"en": "Sync Now", "si": "දැන් සමමුහුර්ත කරන්න"},
    "synced": {"en": "Synced", "si": "සමමුහුර්ත කර ඇත"},
    "pendingSync": {"en": "Pending sync", "si": "සමමුහුර්ත වීමට ඇත"},
    "dayOf": {"en": "Day", "si": "දිනය"},
    "complete": {"en": "complete", "si": "සම්පූර්ණයි"},
    "overdue": {"en": "⚠️ Overdue — please complete this step.", "si": "⚠️ ප්‍රමාද වී ඇත — කරුණාකර මෙම පියවර සම්පූර්ණ කරන්න."},
    "needFundsQuestion": {
      "en": "Need funds for seeds or inputs? Get sponsored by urban investors.",
      "si": "බීජ හෝ ද්‍රව්‍ය සඳහා අරමුදල් අවශ්‍යද? නාගරික ආයෝජකයන්ගෙන් අනුග්‍රහය ලබාගන්න.",
    },
    "requestFunding": {"en": "Request Funding", "si": "අරමුදල් ඉල්ලන්න"},

    "scanCropForDisease": {"en": "Scan your crop for disease", "si": "රෝග සඳහා ඔබේ බෝගය පරීක්ෂා කරන්න"},
    "scanCropSubtitle": {
      "en": "Take a clear photo of the affected leaf or plant part.",
      "si": "බලපෑමට ලක්වූ කොළය හෝ ශාක කොටසේ පැහැදිලි ඡායාරූපයක් ගන්න.",
    },
    "cropTypeHint": {"en": "Crop type (e.g. Tomato)", "si": "බෝග වර්ගය (උදා: තක්කාලි)"},
    "camera": {"en": "Camera", "si": "කැමරාව"},
    "gallery": {"en": "Gallery", "si": "ගැලරිය"},
    "diagnose": {"en": "Diagnose", "si": "රෝග විනිශ්චය කරන්න"},

    "agriAssistant": {"en": "Agri Assistant", "si": "කෘෂි සහායක"},
    "chatPlaceholder": {
      "en": "Ask me anything about your crops — weather, pests, prices, or your timeline.",
      "si": "ඔබේ බෝග ගැන ඕනෑම දෙයක් අසන්න — කාලගුණය, පළිබෝධ, මිල ගණන් හෝ ඔබේ කාලසටහන.",
    },
    "typeYourQuestion": {"en": "Type your question…", "si": "ඔබේ ප්‍රශ්නය ටයිප් කරන්න…"},
    "assistantTyping": {"en": "Assistant is typing…", "si": "සහායක ටයිප් කරමින්..."},
    "listening": {"en": "Listening…", "si": "සවන් දෙමින්..."},
    "tapToSpeak": {"en": "Tap the mic and speak", "si": "මයික්‍රොෆෝනය ස්පර්ශ කර කතා කරන්න"},

    "logout": {"en": "Logout", "si": "ඉවත් වන්න"},

    // ---- Marketplace ----
    "listYourHarvest": {"en": "List your harvest", "si": "ඔබේ අස්වැන්න ලැයිස්තුගත කරන්න"},
    "cropTypeLabel": {"en": "Crop type", "si": "බෝග වර්ගය"},
    "quantityKg": {"en": "Quantity (kg)", "si": "ප්‍රමාණය (kg)"},
    "askingPrice": {"en": "Your asking price (LKR/kg)", "si": "ඔබේ මිල ගණන් (රු./kg)"},
    "listOnMarketplace": {"en": "List on Marketplace", "si": "වෙළඳපොළේ ලැයිස්තුගත කරන්න"},
    "myListings": {"en": "My listings", "si": "මගේ ලැයිස්තු"},
    "noListingsYet": {"en": "No listings yet.", "si": "තවම ලැයිස්තු නැත."},

    // ---- Logistics ----
    "destinationHub": {"en": "Destination hub", "si": "ගමනාන්ත මධ්‍යස්ථානය"},
    "requestSpace": {"en": "Request", "si": "ඉල්ලන්න"},
    "noTrucksFound": {"en": "No trucks found nearby with spare capacity right now.", "si": "දැනට ඉඩ ඇති කිසිදු වාහනයක් ආසන්නයේ හමු නොවීය."},

    // ---- Driver ----
    "tripStatus": {"en": "Trip status", "si": "ගමන් තත්ත්වය"},
    "startTrip": {"en": "Start Trip", "si": "ගමන ආරම්භ කරන්න"},
    "updateTripStatus": {"en": "Update Trip Status", "si": "ගමන් තත්ත්වය යාවත්කාලීන කරන්න"},
    "liveTracking": {"en": "Live GPS tracking (visible to farmers)", "si": "සජීවී GPS ලුහුබැඳීම (ගොවීන්ට පෙනේ)"},
    "pendingRequests": {"en": "Pending cargo requests", "si": "සමතුබත් භාණ්ඩ ඉල්ලීම්"},
    "activeBookings": {"en": "Active bookings", "si": "ක්‍රියාත්මක වෙන්කිරීම්"},
    "noNewRequests": {"en": "No new requests.", "si": "නව ඉල්ලීම් නැත."},

    // ---- Reminders ----
    "reminders": {"en": "Reminders", "si": "මතක් කිරීම්"},
    "allCaughtUp": {"en": "You're all caught up", "si": "ඔබ සියල්ල නවීකරණය කර ඇත"},
    "gotIt": {"en": "Got it", "si": "තේරුණා"},
    "uploadPhoto": {"en": "Upload Photo", "si": "ඡායාරූපය උඩුගත කරන්න"},

    // ---- Forgot Password ----
    "resetPassword": {"en": "Reset Password", "si": "මුරපදය යළි සකසන්න"},
    "sendResetCode": {"en": "Send Reset Code", "si": "යළි සැකසුම් කේතය යවන්න"},
    "sixDigitCode": {"en": "6-digit code", "si": "අංක 6 කේතය"},
    "newPassword": {"en": "New password (min 6 characters)", "si": "නව මුරපදය (අවම අක්ෂර 6ක්)"},

    // ---- Suppliers ----
    "nearbySuppliers": {"en": "Nearby Suppliers & Rentals", "si": "ආසන්න සැපයුම්කරුවන් සහ කුලියට ගැනීම්"},
    "seedStores": {"en": "Seed & Input Stores", "si": "බීජ හා ද්‍රව්‍ය සාප්පු"},
    "equipmentRentals": {"en": "Equipment Rentals", "si": "යන්ත්‍රෝපකරණ කුලියට ගැනීම්"},
    "findNearbySuppliers": {"en": "Find Nearby Stores & Rentals", "si": "ආසන්න සාප්පු සහ කුලී සේවා සොයන්න"},
    "call": {"en": "Call", "si": "අමතන්න"},
    "verified": {"en": "Verified", "si": "සත්‍යාපිත"},
    "dailyRate": {"en": "Daily rate", "si": "දෛනික ගාස්තුව"},
    "noSuppliersFound": {"en": "No suppliers found nearby yet.", "si": "ආසන්නයේ සැපයුම්කරුවන් හමු නොවීය."},

    // ---- Seasonal Calendar ----
    "seasonalCalendar": {"en": "Seasonal Planting Calendar", "si": "සෘතුමය වගා දින දර්ශනය"},
    "bestTimeToPlant": {"en": "Best crops to plant this month", "si": "මෙම මාසයේ සිටුවීමට හොඳම බෝග"},
    "noCropsForMonth": {"en": "No specific recommendations for this month — check a nearby month.", "si": "මෙම මාසය සඳහා විශේෂිත නිර්දේශ නැත — ආසන්න මාසයක් බලන්න."},
    "month1": {"en": "January", "si": "ජනවාරි"},
    "month2": {"en": "February", "si": "පෙබරවාරි"},
    "month3": {"en": "March", "si": "මාර්තු"},
    "month4": {"en": "April", "si": "අප්‍රේල්"},
    "month5": {"en": "May", "si": "මැයි"},
    "month6": {"en": "June", "si": "ජූනි"},
    "month7": {"en": "July", "si": "ජූලි"},
    "month8": {"en": "August", "si": "අගෝස්තු"},
    "month9": {"en": "September", "si": "සැප්තැම්බර්"},
    "month10": {"en": "October", "si": "ඔක්තෝබර්"},
    "month11": {"en": "November", "si": "නොවැම්බර්"},
    "month12": {"en": "December", "si": "දෙසැම්බර්"},

    // ---- Onboarding ----
    "onboardTitle1": {"en": "Plan your crop with confidence", "si": "විශ්වාසයෙන් ඔබේ බෝගය සැලසුම් කරන්න"},
    "onboardDesc1": {
      "en": "Get AI crop recommendations for your soil and climate zone, then follow a day-by-day timeline — even offline.",
      "si": "ඔබේ පස සහ දේශගුණික කලාපයට AI බෝග නිර්දේශ ලබාගෙන, දිනෙන් දින කාලසටහනක් අනුගමනය කරන්න — නොබැඳිව වුවත්.",
    },
    "onboardTitle2": {"en": "Catch problems early", "si": "ගැටලු කලින් අඳුනාගන්න"},
    "onboardDesc2": {
      "en": "Scan a leaf photo to diagnose disease instantly, get weather-based reminders, and ask your Agri Assistant anything — by voice or text.",
      "si": "රෝග ක්ෂණිකව හඳුනාගැනීමට කොළයක ඡායාරූපයක් ගන්න, කාලගුණ මතක් කිරීම් ලබාගන්න, හඬින් හෝ ලියා ඔබේ කෘෂි සහායකගෙන් ඕනෑම දෙයක් අසන්න.",
    },
    "onboardTitle3": {"en": "Sell smarter, waste less", "si": "දක්ෂ ලෙස විකුණන්න, අඩුවෙන් නාස්ති කරන්න"},
    "onboardDesc3": {
      "en": "List your harvest on the marketplace with AI price predictions. Even rejected batches get redirected instead of thrown away.",
      "si": "AI මිල පුරෝකථන සමඟ ඔබේ අස්වැන්න වෙළඳපොළේ ලැයිස්තුගත කරන්න. ප්‍රතික්ෂේප කළ තොග පවා විසි නොකර යළි යොමු කෙරේ.",
    },
    "onboardTitle4": {"en": "Get funded, get moving", "si": "අරමුදල් ලබාගෙන ඉදිරියට යන්න"},
    "onboardDesc4": {
      "en": "Request funding from urban investors for seeds and inputs, find nearby stores and equipment rentals, all in Sinhala or English.",
      "si": "බීජ හා ද්‍රව්‍ය සඳහා නාගරික ආයෝජකයන්ගෙන් අරමුදල් ඉල්ලන්න, ආසන්න සාප්පු සහ කුලී යන්ත්‍රෝපකරණ සොයන්න, සියල්ල සිංහල හෝ ඉංග්‍රීසි භාෂාවෙන්.",
    },
    "skip": {"en": "Skip", "si": "මගහරින්න"},
    "next": {"en": "Next", "si": "ඊළඟට"},
    "getStarted": {"en": "Get Started", "si": "ආරම්භ කරන්න"},

    // ---- Profile ----
    "profile": {"en": "Profile", "si": "පැතිකඩ"},
    "creditScore": {"en": "Credit Score", "si": "ණය ලකුණු"},
    "creditScoreBuilding": {"en": "Building", "si": "ගොඩනගමින්"},
    "creditScoreGood": {"en": "Good", "si": "හොඳයි"},
    "creditScoreExcellent": {"en": "Excellent", "si": "විශිෂ්ටයි"},
    "completedTimelines": {"en": "Completed Seasons", "si": "සම්පූර්ණ කළ වාරි"},
    "activeTimelines": {"en": "Active Timelines", "si": "ක්‍රියාත්මක කාලසටහන්"},
    "settings": {"en": "Settings", "si": "සැකසුම්"},
    "darkMode": {"en": "Dark Mode", "si": "අඳුරු ප්‍රකාරය"},
    "language": {"en": "Language", "si": "භාෂාව"},
    "appVersion": {"en": "ගොවි Tech 2.0", "si": "ගොවි Tech 2.0"},
    "logoutConfirm": {"en": "Are you sure you want to logout?", "si": "ඔබට ඉවත් වීමට අවශ්‍ය බව විශ්වාසද?"},
    "cancel": {"en": "Cancel", "si": "අවලංගු කරන්න"},
  };
}
