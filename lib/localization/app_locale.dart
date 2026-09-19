import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'tr.dart';

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

  String _languageCode = "en"; // "en", "si" or "ta"

  /// Every language the app can show, in the order the picker lists them.
  static const List<String> supportedCodes = ["en", "si", "ta"];

  /// How each language writes its own name (shown in the picker).
  static const Map<String, String> languageNames = {"en": "English", "si": "සිංහල", "ta": "தமிழ்"};

  /// Very short label for compact buttons.
  static const Map<String, String> languageShort = {"en": "EN", "si": "සිං", "ta": "த"};
  String get languageCode => _languageCode;

  static const _prefsKey = "app_language_code";

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    _languageCode = supportedCodes.contains(saved) ? saved! : "en";
    notifyListeners();
  }

  /// en -> si -> ta -> en. Handy for one-tap buttons.
  Future<void> cycleLanguage() {
    final next = supportedCodes[(supportedCodes.indexOf(_languageCode) + 1) % supportedCodes.length];
    return setLanguage(next);
  }

  Future<void> setLanguage(String code) async {
    if (!supportedCodes.contains(code)) return;
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, code);
  }

  /// Speech recognition / TTS locale ID for the current language.
  String get speechLocaleId {
    switch (_languageCode) {
      case "si":
        return "si-LK";
      case "ta":
        return "ta-LK";
      default:
        return "en-US";
    }
  }

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
    "appName": {"en": "ගොවි Tech", "si": "ගොවි Tech", "ta": "ගොවි Tech"},
    "tagline": {"en": "Smart Agriculture Ecosystem", "si": "ස්මාර්ට් කෘෂිකර්ම පද්ධතිය", "ta": "ஸ்மார்ட் விவசாய சூழல் அமைப்பு"},
    "signInToContinue": {"en": "Sign in to continue", "si": "ඉදිරියට යාමට පිවිසෙන්න", "ta": "தொடர உள்நுழையவும்"},

    "email": {"en": "Email", "si": "විද්‍යුත් තැපෑල", "ta": "மின்னஞ்சல்"},
    "password": {"en": "Password", "si": "මුරපදය", "ta": "கடவுச்சொல்"},
    "forgotPassword": {"en": "Forgot password?", "si": "මුරපදය අමතකද?", "ta": "கடவுச்சொல்லை மறந்துவிட்டீர்களா?"},
    "login": {"en": "Login", "si": "පිවිසෙන්න", "ta": "உள்நுழை"},
    "dontHaveAccount": {"en": "Don't have an account? Register", "si": "ගිණුමක් නැද්ද? ලියාපදිංචි වන්න", "ta": "கணக்கு இல்லையா? பதிவு செய்யுங்கள்"},
    "createAccount": {"en": "Create Account", "si": "ගිණුමක් සාදන්න", "ta": "கணக்கை உருவாக்கு"},
    "fullName": {"en": "Full name", "si": "සම්පූර්ණ නම", "ta": "முழுப் பெயர்"},
    "phoneNumber": {"en": "Phone number", "si": "දුරකථන අංකය", "ta": "தொலைபேசி எண்"},
    "district": {"en": "District", "si": "දිස්ත්‍රික්කය", "ta": "மாவட்டம்"},
    "iAmA": {"en": "I am a…", "si": "මම වන්නේ…", "ta": "நான் ஒரு…"},
    "farmer": {"en": "Farmer", "si": "ගොවියා", "ta": "விவசாயி"},
    "truckDriver": {"en": "Truck Driver", "si": "රථ රියදුරු", "ta": "லாரி ஓட்டுநர்"},
    "vehicleRegNo": {"en": "Vehicle registration number", "si": "වාහන ලියාපදිංචි අංකය", "ta": "வாகனப் பதிவு எண்"},
    "vehicleCapacity": {"en": "Vehicle capacity (kg)", "si": "වාහන ධාරිතාව (kg)", "ta": "வாகனத் திறன் (கி.கி.)"},
    "passwordMin": {"en": "Password (min 6 characters)", "si": "මුරපදය (අවම අක්ෂර 6ක්)", "ta": "கடவுச்சொல் (குறைந்தது 6 எழுத்துகள்)"},

    "myTimelines": {"en": "My Timelines", "si": "මගේ වගා කාලසටහන්", "ta": "என் பயிர் காலவரிசைகள்"},
    "cropNavigator": {"en": "Crop Navigator", "si": "බෝග මාර්ගෝපදේශකය", "ta": "பயிர் வழிகாட்டி"},
    "diseaseScanner": {"en": "Disease Scanner", "si": "රෝග පරීක්ෂකය", "ta": "நோய் ஸ்கேனர்"},
    "logistics": {"en": "Logistics", "si": "ප්‍රවාහනය", "ta": "போக்குவரத்து"},
    "marketplace": {"en": "Marketplace", "si": "වෙළඳපොළ", "ta": "சந்தை"},
    "timelines": {"en": "Timelines", "si": "කාලසටහන්", "ta": "காலவரிசை"},
    "navigator": {"en": "Navigator", "si": "මාර්ගෝපදේශකය", "ta": "வழிகாட்டி"},
    "scanner": {"en": "Scanner", "si": "පරීක්ෂකය", "ta": "ஸ்கேனர்"},
    "market": {"en": "Market", "si": "වෙළඳපොළ", "ta": "சந்தை"},

    "tellUsAboutLand": {"en": "Tell us about your land", "si": "ඔබේ ඉඩම ගැන අපට කියන්න", "ta": "உங்கள் நிலத்தைப் பற்றி சொல்லுங்கள்"},
    "landSizeAcres": {"en": "Land size (acres)", "si": "ඉඩම් ප්‍රමාණය (අක්කර)", "ta": "நில அளவு (ஏக்கர்)"},
    "soilType": {"en": "Soil type", "si": "පස් වර්ගය", "ta": "மண் வகை"},
    "getCropRecommendations": {"en": "Get Crop Recommendations", "si": "බෝග නිර්දේශ ලබාගන්න", "ta": "பயிர் பரிந்துரைகளைப் பெறுங்கள்"},
    "recommendedCrops": {"en": "Recommended crops for your soil:", "si": "ඔබේ පසට නිර්දේශිත බෝග:", "ta": "உங்கள் மண்ணுக்குப் பரிந்துரைக்கப்பட்ட பயிர்கள்:"},
    "growthCycle": {"en": "Growth cycle", "si": "වර්ධන චක්‍රය", "ta": "வளர்ச்சி சுழற்சி"},
    "days": {"en": "days", "si": "දින", "ta": "நாட்கள்"},
    "startTimeline": {"en": "Start Timeline", "si": "කාලසටහන ආරම්භ කරන්න", "ta": "காலவரிசையைத் தொடங்கு"},

    "noActiveTimelines": {"en": "No active timelines yet.", "si": "තවම ක්‍රියාත්මක කාලසටහන් නැත.", "ta": "இன்னும் செயலில் உள்ள காலவரிசை இல்லை."},
    "goToNavigatorHint": {"en": "Go to the Navigator tab to start one!", "si": "එකක් ආරම්භ කිරීමට Navigator ටැබයට යන්න!", "ta": "ஒன்றைத் தொடங்க வழிகாட்டி தாவலுக்குச் செல்லுங்கள்!"},
    "worksOffline": {
      "en": "Works fully offline. Syncs automatically when you're back online.",
      "si": "සම්පූර්ණයෙන්ම නොබැඳිව ක්‍රියා කරයි. නැවත සම්බන්ධ වූ විට ස්වයංක්‍රීයව සමමුහුර්ත වේ.",
    },
    "syncNow": {"en": "Sync Now", "si": "දැන් සමමුහුර්ත කරන්න", "ta": "இப்போது ஒத்திசை"},
    "synced": {"en": "Synced", "si": "සමමුහුර්ත කර ඇත", "ta": "ஒத்திசைக்கப்பட்டது"},
    "pendingSync": {"en": "Pending sync", "si": "සමමුහුර්ත වීමට ඇත", "ta": "ஒத்திசைவு நிலுவையில்"},
    "dayOf": {"en": "Day", "si": "දිනය", "ta": "நாள்"},
    "complete": {"en": "complete", "si": "සම්පූර්ණයි", "ta": "முடிந்தது"},
    "overdue": {"en": "⚠️ Overdue — please complete this step.", "si": "⚠️ ප්‍රමාද වී ඇත — කරුණාකර මෙම පියවර සම්පූර්ණ කරන්න.", "ta": "⚠️ காலதாமதம் — இந்தப் படியை முடிக்கவும்."},
    "needFundsQuestion": {
      "en": "Need funds for seeds or inputs? Get sponsored by urban investors.",
      "si": "බීජ හෝ ද්‍රව්‍ය සඳහා අරමුදල් අවශ්‍යද? නාගරික ආයෝජකයන්ගෙන් අනුග්‍රහය ලබාගන්න.",
    },
    "requestFunding": {"en": "Request Funding", "si": "අරමුදල් ඉල්ලන්න", "ta": "நிதி கோரு"},
    "repayInvestors": {"en": "Repay Investors", "si": "ආයෝජකයින්ට ආපසු ගෙවන්න", "ta": "முதலீட்டாளர்களுக்குத் திருப்பிச் செலுத்து"},
    "repaySuccess": {"en": "Campaign repaid! Your credit score has increased.", "si": "අරමුදල ආපසු ගෙවන ලදී! ඔබේ ණය ලකුණු වැඩි විය.", "ta": "திருப்பிச் செலுத்தப்பட்டது! உங்கள் கடன் மதிப்பெண் உயர்ந்துள்ளது."},

    "scanCropForDisease": {"en": "Scan your crop for disease", "si": "රෝග සඳහා ඔබේ බෝගය පරීක්ෂා කරන්න", "ta": "உங்கள் பயிரில் நோயைச் சோதியுங்கள்"},
    "scanCropSubtitle": {
      "en": "Take a clear photo of the affected leaf or plant part.",
      "si": "බලපෑමට ලක්වූ කොළය හෝ ශාක කොටසේ පැහැදිලි ඡායාරූපයක් ගන්න.",
    },
    "cropTypeHint": {"en": "Crop type (e.g. Tomato)", "si": "බෝග වර්ගය (උදා: තක්කාලි)", "ta": "பயிர் வகை (எ.கா. தக்காளி)"},
    "camera": {"en": "Camera", "si": "කැමරාව", "ta": "கேமரா"},
    "gallery": {"en": "Gallery", "si": "ගැලරිය", "ta": "கேலரி"},
    "diagnose": {"en": "Diagnose", "si": "රෝග විනිශ්චය කරන්න", "ta": "நோயறி"},
    "healthyCrop": {"en": "No disease detected. Your crop looks healthy!", "si": "රෝගයක් හඳුනාගත නොහැක. ඔබේ බෝගය සෞඛ්‍ය සම්පන්නයි!", "ta": "நோய் எதுவும் கண்டறியப்படவில்லை. உங்கள் பயிர் ஆரோக்கியமாக உள்ளது!"},
    "severityLabel": {"en": "Severity", "si": "බරපතලකම", "ta": "தீவிரம்"},
    "recommendedTreatmentLabel": {"en": "Recommended treatment", "si": "නිර්දේශිත ප්‍රතිකාරය", "ta": "பரிந்துரைக்கப்பட்ட சிகிச்சை"},
    "regionalOutbreakAlertLabel": {"en": "Regional Outbreak Alert", "si": "ප්‍රාදේශීය රෝග පැතිරීමේ අනතුරු ඇඟවීම", "ta": "பிராந்திய நோய்ப் பரவல் எச்சரிக்கை"},
    "readAloud": {"en": "Read aloud", "si": "හඬින් කියවන්න", "ta": "உரக்கப் படி"},

    "agriAssistant": {"en": "Agri Assistant", "si": "කෘෂි සහායක", "ta": "விவசாய உதவியாளர்"},
    "chatPlaceholder": {
      "en": "Ask me anything about your crops — weather, pests, prices, or your timeline.",
      "si": "ඔබේ බෝග ගැන ඕනෑම දෙයක් අසන්න — කාලගුණය, පළිබෝධ, මිල ගණන් හෝ ඔබේ කාලසටහන.",
    },
    "typeYourQuestion": {"en": "Type your question…", "si": "ඔබේ ප්‍රශ්නය ටයිප් කරන්න…", "ta": "உங்கள் கேள்வியை உள்ளிடுங்கள்…"},
    "assistantTyping": {"en": "Assistant is typing…", "si": "සහායක ටයිප් කරමින්...", "ta": "உதவியாளர் தட்டச்சு செய்கிறார்…"},
    "listening": {"en": "Listening…", "si": "සවන් දෙමින්...", "ta": "கேட்கிறது…"},
    "tapToSpeak": {"en": "Tap the mic and speak", "si": "මයික්‍රොෆෝනය ස්පර්ශ කර කතා කරන්න", "ta": "மைக்கைத் தட்டிப் பேசுங்கள்"},

    "logout": {"en": "Logout", "si": "ඉවත් වන්න", "ta": "வெளியேறு"},

    // ---- Marketplace ----
    "listYourHarvest": {"en": "List your harvest", "si": "ඔබේ අස්වැන්න ලැයිස්තුගත කරන්න", "ta": "உங்கள் அறுவடையைப் பட்டியலிடுங்கள்"},
    "cropTypeLabel": {"en": "Crop type", "si": "බෝග වර්ගය", "ta": "பயிர் வகை"},
    "quantityKg": {"en": "Quantity (kg)", "si": "ප්‍රමාණය (kg)", "ta": "அளவு (கி.கி.)"},
    "askingPrice": {"en": "Your asking price (LKR/kg)", "si": "ඔබේ මිල ගණන් (රු./kg)", "ta": "உங்கள் விலை (ரூ/கி.கி.)"},
    "listOnMarketplace": {"en": "List on Marketplace", "si": "වෙළඳපොළේ ලැයිස්තුගත කරන්න", "ta": "சந்தையில் பட்டியலிடு"},
    "myListings": {"en": "My listings", "si": "මගේ ලැයිස්තු", "ta": "என் பட்டியல்கள்"},
    "noListingsYet": {"en": "No listings yet.", "si": "තවම ලැයිස්තු නැත.", "ta": "இன்னும் பட்டியல்கள் இல்லை."},
    "editListing": {"en": "Edit", "si": "සංස්කරණය", "ta": "திருத்து"},
    "saveChanges": {"en": "Save Changes", "si": "වෙනස්කම් සුරකින්න", "ta": "மாற்றங்களைச் சேமி"},
    "markAsSold": {"en": "Mark as Sold", "si": "විකුණන ලද ලෙස සලකුණු කරන්න", "ta": "விற்கப்பட்டதாகக் குறி"},
    "markAsSoldConfirm": {"en": "Confirm the buyer has paid and received this order?", "si": "ගැනුම්කරු මෙම ඇණවුම සඳහා ගෙවා ලැබී ඇති බව තහවුරු කරන්නද?", "ta": "வாங்குபவர் பணம் செலுத்தி இந்த ஆர்டரைப் பெற்றதை உறுதிப்படுத்துகிறீர்களா?"},
    "listingUpdated": {"en": "Listing updated.", "si": "ලැයිස්තුව යාවත්කාලීන කරන ලදී.", "ta": "பட்டியல் புதுப்பிக்கப்பட்டது."},
    "saleCompleted": {"en": "Sale marked as complete.", "si": "විකිණීම සම්පූර්ණ කළ ලෙස සලකුණු කරන ලදී.", "ta": "விற்பனை முடிந்ததாகக் குறிக்கப்பட்டது."},

    // ---- Ads ----
    "sponsored": {"en": "Sponsored", "si": "අනුග්‍රහය", "ta": "விளம்பரம்"},

    // ---- Community Marketplace (rentals & seeds) ----
    "communityMarketplace": {"en": "Rentals & Seeds", "si": "කුලියට හා බීජ", "ta": "வாடகை & விதைகள்"},
    "myRentalsAndSeeds": {"en": "My Rentals & Seeds", "si": "මගේ කුලී භාණ්ඩ හා බීජ", "ta": "என் வாடகை & விதைகள்"},
    "postAnItem": {"en": "Post an Item", "si": "අයිතමයක් පළ කරන්න", "ta": "பொருளை இடுகையிடு"},
    "equipmentRental": {"en": "Equipment Rental", "si": "යන්ත්‍ර කුලියට", "ta": "உபகரண வாடகை"},
    "seedsForSale": {"en": "Seeds for Sale", "si": "විකිණීමට බීජ", "ta": "விற்பனைக்கு விதைகள்"},
    "otherItem": {"en": "Other", "si": "වෙනත්", "ta": "மற்றவை"},
    "itemTitle": {"en": "Title (e.g. Two-wheel tractor for rent)", "si": "මාතෘකාව (උදා: කුලියට දුම්රියක්)", "ta": "தலைப்பு (எ.கா. இரு சக்கர டிராக்டர் வாடகைக்கு)"},
    "itemDescription": {"en": "Description", "si": "විස්තරය", "ta": "விவரம்"},
    "priceAmount": {"en": "Price", "si": "මිල", "ta": "விலை"},
    "priceUnit": {"en": "Unit (e.g. per day, per kg, fixed)", "si": "ඒකකය (උදා: දිනකට, kg කට, ස්ථිර)", "ta": "அலகு (எ.கா. ஒரு நாளைக்கு, கி.கி.க்கு, நிலையானது)"},
    "contactPhoneLabel": {"en": "Contact phone", "si": "සම්බන්ධ වීමට දුරකථන අංකය", "ta": "தொடர்பு தொலைபேசி"},
    "postListing": {"en": "Post Listing", "si": "ලැයිස්තුව පළ කරන්න", "ta": "பட்டியலை இடுகையிடு"},
    "noCommunityListingsFound": {"en": "No rentals or seeds posted nearby yet.", "si": "ආසන්නයේ කුලී භාණ්ඩ හෝ බීජ තවම පළ කර නැත.", "ta": "அருகில் இன்னும் வாடகை அல்லது விதைகள் இடுகையிடப்படவில்லை."},
    "callToInquire": {"en": "Call", "si": "අමතන්න", "ta": "அழை"},
    "deactivate": {"en": "Deactivate", "si": "අක්‍රිය කරන්න", "ta": "செயலிழக்கச் செய்"},
    "activate": {"en": "Activate", "si": "සක්‍රිය කරන්න", "ta": "செயல்படுத்து"},
    "deleteListing": {"en": "Delete", "si": "මකන්න", "ta": "நீக்கு"},
    "active": {"en": "Active", "si": "සක්‍රියයි", "ta": "செயலில்"},
    "inactive": {"en": "Inactive", "si": "අක්‍රියයි", "ta": "செயலற்றது"},

    // ---- Logistics ----
    "destinationHub": {"en": "Destination hub", "si": "ගමනාන්ත මධ්‍යස්ථානය", "ta": "சேருமிட மையம்"},
    "requestSpace": {"en": "Request", "si": "ඉල්ලන්න", "ta": "கோரு"},
    "noTrucksFound": {"en": "No trucks found nearby with spare capacity right now.", "si": "දැනට ඉඩ ඇති කිසිදු වාහනයක් ආසන්නයේ හමු නොවීය.", "ta": "தற்போது அருகில் இடம் உள்ள லாரிகள் இல்லை."},

    // ---- Driver ----
    "tripStatus": {"en": "Trip status", "si": "ගමන් තත්ත්වය", "ta": "பயண நிலை"},
    "startTrip": {"en": "Start Trip", "si": "ගමන ආරම්භ කරන්න", "ta": "பயணத்தைத் தொடங்கு"},
    "updateTripStatus": {"en": "Update Trip Status", "si": "ගමන් තත්ත්වය යාවත්කාලීන කරන්න", "ta": "பயண நிலையைப் புதுப்பி"},
    "liveTracking": {"en": "Live GPS tracking (visible to farmers)", "si": "සජීවී GPS ලුහුබැඳීම (ගොවීන්ට පෙනේ)", "ta": "நேரடி GPS கண்காணிப்பு (விவசாயிகளுக்குத் தெரியும்)"},
    "pendingRequests": {"en": "Pending cargo requests", "si": "සමතුබත් භාණ්ඩ ඉල්ලීම්", "ta": "நிலுவையில் உள்ள சரக்கு கோரிக்கைகள்"},
    "activeBookings": {"en": "Active bookings", "si": "ක්‍රියාත්මක වෙන්කිරීම්", "ta": "செயலில் உள்ள முன்பதிவுகள்"},
    "noNewRequests": {"en": "No new requests.", "si": "නව ඉල්ලීම් නැත.", "ta": "புதிய கோரிக்கைகள் இல்லை."},

    // ---- Reminders ----
    "reminders": {"en": "Reminders", "si": "මතක් කිරීම්", "ta": "நினைவூட்டல்கள்"},
    "allCaughtUp": {"en": "You're all caught up", "si": "ඔබ සියල්ල නවීකරණය කර ඇත", "ta": "எல்லாம் முடிந்தது"},
    "gotIt": {"en": "Got it", "si": "තේරුණා", "ta": "சரி"},
    "uploadPhoto": {"en": "Upload Photo", "si": "ඡායාරූපය උඩුගත කරන්න", "ta": "புகைப்படம் பதிவேற்று"},

    // ---- Forgot Password ----
    "resetPassword": {"en": "Reset Password", "si": "මුරපදය යළි සකසන්න", "ta": "கடவுச்சொல்லை மீட்டமை"},
    "sendResetCode": {"en": "Send Reset Code", "si": "යළි සැකසුම් කේතය යවන්න", "ta": "மீட்டமைப்புக் குறியீட்டை அனுப்பு"},
    "sixDigitCode": {"en": "6-digit code", "si": "අංක 6 කේතය", "ta": "6 இலக்கக் குறியீடு"},
    "newPassword": {"en": "New password (min 6 characters)", "si": "නව මුරපදය (අවම අක්ෂර 6ක්)", "ta": "புதிய கடவுச்சொல் (குறைந்தது 6 எழுத்துகள்)"},

    // ---- Suppliers ----
    "nearbySuppliers": {"en": "Nearby Suppliers & Rentals", "si": "ආසන්න සැපයුම්කරුවන් සහ කුලියට ගැනීම්", "ta": "அருகிலுள்ள விநியோகஸ்தர்கள் & வாடகை"},
    "seedStores": {"en": "Seed & Input Stores", "si": "බීජ හා ද්‍රව්‍ය සාප්පු", "ta": "விதை & இடுபொருள் கடைகள்"},
    "equipmentRentals": {"en": "Equipment Rentals", "si": "යන්ත්‍රෝපකරණ කුලියට ගැනීම්", "ta": "உபகரண வாடகை"},
    "findNearbySuppliers": {"en": "Find Nearby Stores & Rentals", "si": "ආසන්න සාප්පු සහ කුලී සේවා සොයන්න", "ta": "அருகிலுள்ள கடைகள் & வாடகையைக் கண்டறி"},
    "call": {"en": "Call", "si": "අමතන්න", "ta": "அழை"},
    "verified": {"en": "Verified", "si": "සත්‍යාපිත", "ta": "சரிபார்க்கப்பட்டது"},
    "dailyRate": {"en": "Daily rate", "si": "දෛනික ගාස්තුව", "ta": "தினசரி கட்டணம்"},
    "noSuppliersFound": {"en": "No suppliers found nearby yet.", "si": "ආසන්නයේ සැපයුම්කරුවන් හමු නොවීය.", "ta": "அருகில் இன்னும் விநியோகஸ்தர்கள் இல்லை."},
    "viewOnMap": {"en": "View on Map", "si": "සිතියමේ බලන්න", "ta": "வரைபடத்தில் பார்"},
    "listView": {"en": "List", "si": "ලැයිස්තුව", "ta": "பட்டியல்"},
    "mapView": {"en": "Map", "si": "සිතියම", "ta": "வரைபடம்"},
    "getDirections": {"en": "Directions", "si": "දිශාව", "ta": "வழிகாட்டு"},

    // ---- Seasonal Calendar ----
    "seasonalCalendar": {"en": "Seasonal Planting Calendar", "si": "සෘතුමය වගා දින දර්ශනය", "ta": "பருவகால நடவு நாட்காட்டி"},
    "bestTimeToPlant": {"en": "Best crops to plant this month", "si": "මෙම මාසයේ සිටුවීමට හොඳම බෝග", "ta": "இந்த மாதம் நடவு செய்ய சிறந்த பயிர்கள்"},
    "noCropsForMonth": {"en": "No specific recommendations for this month — check a nearby month.", "si": "මෙම මාසය සඳහා විශේෂිත නිර්දේශ නැත — ආසන්න මාසයක් බලන්න.", "ta": "இந்த மாதத்திற்குக் குறிப்பிட்ட பரிந்துரைகள் இல்லை — அருகிலுள்ள மாதத்தைப் பாருங்கள்."},
    "month1": {"en": "January", "si": "ජනවාරි", "ta": "ஜனவரி"},
    "month2": {"en": "February", "si": "පෙබරවාරි", "ta": "பிப்ரவரி"},
    "month3": {"en": "March", "si": "මාර්තු", "ta": "மார்ச்"},
    "month4": {"en": "April", "si": "අප්‍රේල්", "ta": "ஏப்ரல்"},
    "month5": {"en": "May", "si": "මැයි", "ta": "மே"},
    "month6": {"en": "June", "si": "ජූනි", "ta": "ஜூன்"},
    "month7": {"en": "July", "si": "ජූලි", "ta": "ஜூலை"},
    "month8": {"en": "August", "si": "අගෝස්තු", "ta": "ஆகஸ்ட்"},
    "month9": {"en": "September", "si": "සැප්තැම්බර්", "ta": "செப்டம்பர்"},
    "month10": {"en": "October", "si": "ඔක්තෝබර්", "ta": "அக்டோபர்"},
    "month11": {"en": "November", "si": "නොවැම්බර්", "ta": "நவம்பர்"},
    "month12": {"en": "December", "si": "දෙසැම්බර්", "ta": "டிசம்பர்"},

    // ---- Onboarding ----
    "onboardTitle1": {"en": "Plan your crop with confidence", "si": "විශ්වාසයෙන් ඔබේ බෝගය සැලසුම් කරන්න", "ta": "நம்பிக்கையுடன் உங்கள் பயிரைத் திட்டமிடுங்கள்"},
    "onboardDesc1": {
      "en": "Get AI crop recommendations for your soil and climate zone, then follow a day-by-day timeline — even offline.",
      "si": "ඔබේ පස සහ දේශගුණික කලාපයට AI බෝග නිර්දේශ ලබාගෙන, දිනෙන් දින කාලසටහනක් අනුගමනය කරන්න — නොබැඳිව වුවත්.",
    },
    "onboardTitle2": {"en": "Catch problems early", "si": "ගැටලු කලින් අඳුනාගන්න", "ta": "பிரச்சினைகளை முன்கூட்டியே கண்டறியுங்கள்"},
    "onboardDesc2": {
      "en": "Scan a leaf photo to diagnose disease instantly, get weather-based reminders, and ask your Agri Assistant anything — by voice or text.",
      "si": "රෝග ක්ෂණිකව හඳුනාගැනීමට කොළයක ඡායාරූපයක් ගන්න, කාලගුණ මතක් කිරීම් ලබාගන්න, හඬින් හෝ ලියා ඔබේ කෘෂි සහායකගෙන් ඕනෑම දෙයක් අසන්න.",
    },
    "onboardTitle3": {"en": "Sell smarter, waste less", "si": "දක්ෂ ලෙස විකුණන්න, අඩුවෙන් නාස්ති කරන්න", "ta": "புத்திசாலித்தனமாக விற்று, வீணாவதைக் குறையுங்கள்"},
    "onboardDesc3": {
      "en": "List your harvest on the marketplace with AI price predictions. Even rejected batches get redirected instead of thrown away.",
      "si": "AI මිල පුරෝකථන සමඟ ඔබේ අස්වැන්න වෙළඳපොළේ ලැයිස්තුගත කරන්න. ප්‍රතික්ෂේප කළ තොග පවා විසි නොකර යළි යොමු කෙරේ.",
    },
    "onboardTitle4": {"en": "Get funded, get moving", "si": "අරමුදල් ලබාගෙන ඉදිරියට යන්න", "ta": "நிதி பெறுங்கள், முன்னேறுங்கள்"},
    "onboardDesc4": {
      "en": "Request funding from urban investors for seeds and inputs, find nearby stores and equipment rentals, all in Sinhala or English.",
      "si": "බීජ හා ද්‍රව්‍ය සඳහා නාගරික ආයෝජකයන්ගෙන් අරමුදල් ඉල්ලන්න, ආසන්න සාප්පු සහ කුලී යන්ත්‍රෝපකරණ සොයන්න, සියල්ල සිංහල හෝ ඉංග්‍රීසි භාෂාවෙන්.",
    },
    "skip": {"en": "Skip", "si": "මගහරින්න", "ta": "தவிர்"},
    "next": {"en": "Next", "si": "ඊළඟට", "ta": "அடுத்து"},
    "getStarted": {"en": "Get Started", "si": "ආරම්භ කරන්න", "ta": "தொடங்குங்கள்"},

    // ---- Profile ----
    "profile": {"en": "Profile", "si": "පැතිකඩ", "ta": "சுயவிவரம்"},
    "creditScore": {"en": "Credit Score", "si": "ණය ලකුණු", "ta": "கடன் மதிப்பெண்"},
    "creditScoreBuilding": {"en": "Building", "si": "ගොඩනගමින්", "ta": "உருவாகிறது"},
    "creditScoreGood": {"en": "Good", "si": "හොඳයි", "ta": "நன்று"},
    "creditScoreExcellent": {"en": "Excellent", "si": "විශිෂ්ටයි", "ta": "சிறப்பு"},
    "completedTimelines": {"en": "Completed Seasons", "si": "සම්පූර්ණ කළ වාරි", "ta": "நிறைவு செய்த பருவங்கள்"},
    "activeTimelines": {"en": "Active Timelines", "si": "ක්‍රියාත්මක කාලසටහන්", "ta": "செயலில் உள்ள காலவரிசைகள்"},
    "settings": {"en": "Settings", "si": "සැකසුම්", "ta": "அமைப்புகள்"},
    "darkMode": {"en": "Dark Mode", "si": "අඳුරු ප්‍රකාරය", "ta": "இருள் பயன்முறை"},
    "language": {"en": "Language", "si": "භාෂාව", "ta": "மொழி"},
    "appVersion": {"en": "ගොවි Tech 2.0", "si": "ගොවි Tech 2.0", "ta": "ගොවි Tech 2.0"},
    "logoutConfirm": {"en": "Are you sure you want to logout?", "si": "ඔබට ඉවත් වීමට අවශ්‍ය බව විශ්වාසද?", "ta": "நிச்சயமாக வெளியேற விரும்புகிறீர்களா?"},
    "cancel": {"en": "Cancel", "si": "අවලංගු කරන්න", "ta": "ரத்து செய்"},
  };
}
