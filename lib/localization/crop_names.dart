import '../services/crop_recommendation_service.dart';
import 'app_locale.dart';

/// Tamil names for the 51 crops in the app's catalogue (the catalogue itself
/// already carries the Sinhala names).
const Map<String, String> _cropNamesTa = {
  "Tomato": "தக்காளி", "Chili": "மிளகாய்", "Okra (Bandakka)": "வெண்டைக்காய்", "Brinjal (Eggplant)": "கத்தரிக்காய்",
  "Cabbage": "முட்டைக்கோசு", "Carrot": "கேரட்", "Beans (Bush)": "பீன்ஸ்", "Cucumber": "வெள்ளரிக்காய்",
  "Pumpkin": "பூசணிக்காய்", "Bitter Gourd": "பாகற்காய்", "Snake Gourd": "புடலங்காய்", "Ash Plantain": "வாழைக்காய்",
  "Beetroot": "பீட்ரூட்", "Leeks": "லீக்ஸ்", "Knol Khol": "நூல்கோல்", "Radish": "முள்ளங்கி",
  "Winged Bean": "சிறகு அவரை", "Onion (Big/Red)": "பெரிய வெங்காயம்", "Banana": "வாழைப்பழம்", "Papaya": "பப்பாளி",
  "Pineapple": "அன்னாசி", "Mango": "மாம்பழம்", "Watermelon": "தர்பூசணி", "Passion Fruit": "பேஷன் பழம்",
  "Guava": "கொய்யா", "Rambutan": "ரம்புட்டான்", "Avocado": "அவகாடோ", "Wood Apple": "விளாம்பழம்", "Lime": "எலுமிச்சை",
  "Paddy (Rice)": "நெல்", "Maize (Corn)": "மக்காச்சோளம்", "Kurakkan (Finger Millet)": "கேழ்வரகு", "Sorghum": "சோளம்",
  "Black Pepper": "மிளகு", "Cinnamon": "இலவங்கப்பட்டை", "Cardamom": "ஏலக்காய்", "Cloves": "கிராம்பு",
  "Nutmeg": "ஜாதிக்காய்", "Ginger": "இஞ்சி", "Turmeric": "மஞ்சள்", "Green Gram (Mung Bean)": "பச்சைப்பயறு",
  "Cowpea": "காராமணி", "Soybean": "சோயாபீன்", "Groundnut (Peanut)": "நிலக்கடலை", "Black Gram (Ulundu)": "உளுந்து",
  "Tea": "தேயிலை", "Rubber": "ரப்பர்", "Coconut": "தென்னை", "Coffee": "காபி", "Arecanut": "பாக்கு", "Cashew": "முந்திரி",
};

/// The crop's Tamil name (falls back to English).
String cropTamilName(CropOption crop) => _cropNamesTa[crop.name] ?? crop.name;

/// The crop's name in the language the farmer is using.
String cropLocalName(CropOption crop) {
  switch (AppLocale.instance.languageCode) {
    case "si":
      return crop.nameSi;
    case "ta":
      return _cropNamesTa[crop.name] ?? crop.name;
    default:
      return crop.name;
  }
}

/// "Tomato · තක්කාලි" (English UI), "තක්කාලි · Tomato" (Sinhala UI), "தக்காளி · Tomato" (Tamil UI).
String cropBilingualTitle(CropOption crop) {
  final local = cropLocalName(crop);
  if (AppLocale.instance.languageCode == "en") return "${crop.name}  ·  ${crop.nameSi}";
  return "$local  ·  ${crop.name}";
}

/// True when [query] matches the crop's English, Sinhala or Tamil name.
bool cropMatchesQuery(CropOption crop, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  return crop.name.toLowerCase().contains(q) || crop.nameSi.contains(query.trim()) || (_cropNamesTa[crop.name] ?? "").contains(query.trim());
}
