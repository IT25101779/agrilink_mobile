/// Tamil text for the 13 fixed cultivation stages every crop timeline is
/// built from. Looked up by the stage's English title at display time, so no
/// stored timeline data (Hive / backend) has to change.
class MilestoneTamil {
  static const Map<String, List<String>> _stages = {
    "Land Preparation": ["நில ஆயத்தம்", "வயலை உழுது சமப்படுத்துங்கள். களைகளையும் குப்பைகளையும் அகற்றுங்கள்."],
    "Soil Testing & Fertilizer Base": ["மண் பரிசோதனை & அடி உரம்", "மண் பரிசோதனைக்கு ஏற்ப அடி உரம் / கம்போஸ்ட் இடுங்கள்."],
    "Sowing / Planting": ["விதைத்தல் / நடவு", "பயிருக்கான விதைகளை அல்லது நாற்றுகளை நடுங்கள்."],
    "First Irrigation Check": ["முதல் நீர்ப்பாசனச் சோதனை", "மண்ணில் போதுமான ஈரம் உள்ளதா என்று பாருங்கள்; வறண்டிருந்தால் நீர் பாய்ச்சுங்கள்."],
    "First Weeding": ["முதல் களையெடுப்பு", "சத்துகளுக்காகப் போட்டியிடும் களைகளை அகற்றுங்கள்."],
    "First Fertilizer Top-up": ["முதல் மேலுரம்", "மேலுரம் இடுங்கள்."],
    "Pest & Disease Inspection": ["பூச்சி & நோய் ஆய்வு", "நோயின் ஆரம்ப அறிகுறிகளுக்காக இலைகளைப் பாருங்கள். புள்ளிகள் தெரிந்தால் நோய் ஸ்கேனரைப் பயன்படுத்துங்கள்."],
    "Second Weeding": ["இரண்டாவது களையெடுப்பு", "மீண்டும் முளைத்த களைகளை அகற்றுங்கள்."],
    "Second Fertilizer Top-up": ["இரண்டாவது மேலுரம்", "பூக்கும் / காய்க்கும் பருவத்துக்காக இரண்டாவது முறை உரம் இடுங்கள்."],
    "Flowering / Fruit Set Monitoring": ["பூப்பு / காய் பிடிப்புக் கண்காணிப்பு", "பூப்பதையும் ஆரம்பக் காய் வளர்ச்சியையும் கவனியுங்கள்."],
    "Pre-Harvest Pest Check": ["அறுவடைக்கு முந்தைய பூச்சிச் சோதனை", "அறுவடைக்கு முன் கடைசி பூச்சி மற்றும் நோய் ஆய்வு செய்யுங்கள்."],
    "Harvest Readiness Check": ["அறுவடைத் தயார்நிலைச் சோதனை", "அறுவடைக்கு முன் முதிர்ச்சி அறிகுறிகளை உறுதிசெய்யுங்கள்."],
    "Harvest": ["அறுவடை", "பயிரை அறுவடை செய்து சந்தைப் பட்டியலுக்குத் தயாராகுங்கள்."],
  };

  static String? title(String englishTitle) => _stages[englishTitle]?[0];

  static String? description(String englishTitle) => _stages[englishTitle]?[1];
}
