/// Offline pest and disease guide. Works with no internet.
/// IMPORTANT: this is general guidance without chemical names or doses on purpose - for sprays and doses the
/// farmer must follow the Department of Agriculture / Agrarian Service Centre. The Sinhala and Tamil text should
/// be checked by an agriculture officer before release.
class PestEntry {
  final String id;
  final String emoji;
  final List<String> crops; // English crop names it mainly affects
  final List<String> name; // [en, si, ta]
  final List<String> signs;
  final List<String> action;
  const PestEntry(this.id, this.emoji, this.crops, this.name, this.signs, this.action);
}

const List<PestEntry> kPestLibrary = [
  PestEntry("late_blight", "🍅", ["Tomato", "Potato"], ["Late blight", "පරිපූර්ණ අංගමාරය (ලේට් බ්ලයිට්)", "தாமத கருகல் நோய்"], [
    "Dark, water-soaked patches on leaves and stems, white fuzzy mould underneath in wet weather; fruit gets brown hard patches. Spreads very fast in cool, rainy spells.",
    "තෙත් කාලගුණයේදී කොළ හා කද මත අඳුරු, දියෙන් පිරි පැල්ලම්; යටින් සුදු පුස්. ගෙඩි මත දුඹුරු තද පැල්ලම්. සීතල, වැසි කාලයේ ඉතා වේගයෙන් පැතිරේ.",
    "இலை, தண்டில் கருமையான நீர் நனைந்த திட்டுகள்; ஈரமான காலத்தில் அடியில் வெள்ளை பூஞ்சை. குளிர், மழையில் வேகமாகப் பரவும்."
  ], [
    "Remove and bury or burn infected plants. Water at the base, not over the leaves. Give plants space and good drainage. Rotate crops. Tell your Agrarian Service Centre early - do not wait for it to spread.",
    "ආසාදිත පැළ ඉවත් කර වළලන්න හෝ පුළුස්සන්න. කොළ මත නොව මුල් අසලට දිය දමන්න. පැළ අතර ඉඩ හා හොඳ ජලාපවහනය තබන්න. බෝග මාරු කරන්න. ගොවිජන සේවා මධ්‍යස්ථානයට කල් තියා දන්වන්න.",
    "பாதித்த செடிகளை அகற்றி புதைக்கவும்/எரிக்கவும். இலை மீது அல்ல, வேரில் நீர் ஊற்றவும். இடைவெளி, நல்ல வடிகால் வையுங்கள். பயிர் சுழற்சி செய்யவும். விவசாய சேவை மையத்திற்கு உடனே தெரிவிக்கவும்."
  ]),
  PestEntry("leaf_curl", "🌿", ["Tomato", "Chilli"], ["Leaf curl (virus, spread by whitefly)", "කොළ හැකිලීම (සුදු මැස්සා මගින් පැතිරෙන වයිරසය)", "இலை சுருட்டு (வெள்ளை ஈ மூலம் பரவும் வைரஸ்)"], [
    "Leaves curl up or down, thicken and turn yellow; plants stay small and give little fruit. Tiny white insects fly up when you shake the plant.",
    "කොළ ඉහළට/පහළට හැකිලී, ඝන වී කහ වේ; පැළ කුඩා වී අස්වැන්න අඩුයි. පැළය සොලවන විට කුඩා සුදු කෘමීන් පියඹයි.",
    "இலைகள் மேலே/கீழே சுருண்டு, தடித்து மஞ்சளாகும்; செடி சிறுத்து விளைச்சல் குறையும். செடியை அசைத்தால் சிறு வெள்ளை பூச்சிகள் பறக்கும்."
  ], [
    "There is no cure - pull out and destroy sick plants early. Use yellow sticky traps, keep weeds down, start with healthy seedlings (cover nursery beds with fine net). Ask your officer about tolerant varieties.",
    "ප්‍රතිකාරයක් නැත - රෝගී පැළ කල් තියා ගලවා විනාශ කරන්න. කහ ඇලෙන කොළ උගුල් භාවිතා කරන්න, වල් පැළෑටි පාලනය කරන්න, නිරෝගී පැල භාවිතා කරන්න (නිවර්තන පාත්ති සියුම් දැලකින් වසන්න). ඔරොත්තු දෙන ප්‍රභේද ගැන නිලධාරියාගෙන් අසන්න.",
    "மருந்து இல்லை - நோயுற்ற செடிகளை முன்கூட்டியே பிடுங்கி அழிக்கவும். மஞ்சள் ஒட்டும் பொறிகள், களை கட்டுப்பாடு, ஆரோக்கியமான நாற்றுகள் (நாற்றங்காலை மெல்லிய வலையால் மூடவும்). தாங்கும் ரகங்கள் பற்றி அலுவலரிடம் கேளுங்கள்."
  ]),
  PestEntry("bacterial_wilt", "🍆", ["Tomato", "Brinjal", "Chilli"], ["Bacterial wilt", "බැක්ටීරියා මැළවීම", "பாக்டீரிய வாடல்"], [
    "The whole plant suddenly wilts while the leaves are still green, often in the afternoon heat, and does not recover at night. Cut stem in a glass of water shows milky threads.",
    "කොළ කොළ පාටින්ම පැළය එකවර මැලවේ; රාත්‍රියේ යථා තත්වයට නොපැමිණේ. කද කපා වතුරේ තැබූ විට කිරි පාට කෙඳි පෙනේ.",
    "இலைகள் பச்சையாக இருக்கும்போதே செடி திடீரெனத் தளரும்; இரவிலும் மீளாது. தண்டை நீரில் வைத்தால் பால் போன்ற இழைகள் தெரியும்."
  ], [
    "No cure. Remove the plant with its roots, do not water other plants from it. Do not plant tomato, brinjal, chilli or potato in that spot for 2-3 seasons; grow maize or another non-related crop. Improve drainage.",
    "ප්‍රතිකාරයක් නැත. පැළය මුල් සමඟ ඉවත් කරන්න. එම ස්ථානයේ කන්න 2-3ක් තක්කාලි, වම්බටු, මිරිස්, අර්තාපල් නොවවන්න; ඉරිඟු වැනි සම්බන්ධ නොවන බෝග වවන්න. ජලාපවහනය වැඩි දියුණු කරන්න.",
    "மருந்து இல்லை. செடியை வேருடன் அகற்றவும். அந்த இடத்தில் 2-3 போகம் தக்காளி, கத்தரி, மிளகாய், உருளை நடாதீர்கள்; சோளம் போன்ற தொடர்பில்லாத பயிர் வளர்க்கவும். வடிகால் மேம்படுத்தவும்."
  ]),
  PestEntry("brinjal_borer", "🍆", ["Brinjal"], ["Brinjal shoot and fruit borer", "වම්බටු දළු හා ගෙඩි විදින පණුවා", "கத்தரி தண்டு, காய் துளைப்பான்"], [
    "Shoot tips wilt and droop; fruits have small holes with dark waste inside.",
    "දළු අග්‍ර මැලවී වැටේ; ගෙඩි වල කුඩා සිදුරු හා ඇතුළත කළු අපද්‍රව්‍ය.",
    "தண்டு நுனிகள் வாடி தொங்கும்; காய்களில் சிறு துளைகளும் உள்ளே கருப்புக் கழிவும்."
  ], [
    "Every few days cut off wilted shoots and pick damaged fruit; destroy them (do not leave in the field). Use pheromone traps to watch numbers. Spraying too often kills helpful insects - ask your officer first.",
    "දින කිහිපයකට වරක් මැලවුණු දළු කපා හානි වූ ගෙඩි ඉවත් කර විනාශ කරන්න (කුඹුරේ නොදමන්න). සංඛ්‍යාව බැලීමට ෆෙරමෝන උගුල් භාවිතා කරන්න. නිතර ඉසීමෙන් ප්‍රයෝජනවත් කෘමීන් මිය යයි - මුලින් නිලධාරියාගෙන් අසන්න.",
    "சில நாட்களுக்கு ஒருமுறை வாடிய நுனிகளை வெட்டி, சேதமான காய்களைப் பறித்து அழிக்கவும். எண்ணிக்கை அறிய இனக்கவர்ச்சி பொறிகள். அடிக்கடி தெளித்தால் நன்மை செய்யும் பூச்சிகள் அழியும் - முதலில் அலுவலரிடம் கேளுங்கள்."
  ]),
  PestEntry("dbm", "🥬", ["Cabbage", "Cauliflower"], ["Diamondback moth", "ඩයමන්ඩ්බැක් සලබයා", "வைரமுதுகு அந்துப்பூச்சி"], [
    "Many small holes and windowed patches in leaves; small green wriggling caterpillars that drop on a thread when touched.",
    "කොළ වල කුඩා සිදුරු රාශියක්; ස්පර්ශ කළ විට නූලකින් වැටෙන කුඩා කොළ පාට පණුවන්.",
    "இலைகளில் பல சிறு துளைகள்; தொட்டால் நூலில் இறங்கும் சிறு பச்சைப் புழுக்கள்."
  ], [
    "Clear crop leftovers after harvest, rotate away from cabbage family, check the underside of leaves weekly. Using the same chemical again and again makes them resistant - follow your Agrarian Service Centre's advice.",
    "අස්වැන්නෙන් පසු ඉතිරි කොටස් ඉවත් කරන්න, ගෝවා කුලයෙන් බෝග මාරු කරන්න, සතියකට වරක් කොළ යට බලන්න. එකම රසායනය නැවත නැවත භාවිතයෙන් ප්‍රතිරෝධය ඇති වේ - ගොවිජන සේවා මධ්‍යස්ථානයේ උපදෙස් අනුගමනය කරන්න.",
    "அறுவடைக்குப் பின் மிச்சங்களை அகற்றவும், முட்டைக்கோஸ் குடும்பத்திலிருந்து மாற்றி பயிரிடவும், வாரம் ஒருமுறை இலை அடியைப் பாருங்கள். ஒரே மருந்தை மீண்டும் பயன்படுத்தினால் எதிர்ப்பு உருவாகும் - விவசாய சேவை மையத்தின் ஆலோசனையைப் பின்பற்றவும்."
  ]),
  PestEntry("paddy_blast", "🌾", ["Rice"], ["Paddy blast", "වී බ්ලාස්ට් (පොල්ල රෝගය)", "நெல் குலை நோய்"], [
    "Diamond-shaped spots with grey centres on leaves; the neck of the panicle can turn brown and break, giving empty grain.",
    "කොළ මත අළු මැදක් සහිත දියමන්ති හැඩැති පැල්ලම්; කරල් බෙල්ල දුඹුරු වී කැඩී හිස් ධාන්‍ය ඇති විය හැක.",
    "இலைகளில் சாம்பல் மையமுள்ள வைர வடிவப் புள்ளிகள்; கதிரின் கழுத்து பழுப்பாகி முறிந்து பதர் ஆகலாம்."
  ], [
    "Do not over-apply nitrogen fertiliser; use recommended, resistant varieties and clean seed paddy; keep fields well managed. Report early to the Agrarian Service Centre - timing matters for any treatment.",
    "නයිට්‍රජන් පොහොර අධිකව නොයොදන්න; නිර්දේශිත, ප්‍රතිරෝධී ප්‍රභේද හා පිරිසිදු බීජ වී භාවිතා කරන්න. ගොවිජන සේවා මධ්‍යස්ථානයට කල් තියා දන්වන්න - ප්‍රතිකාර වලට කාලය වැදගත්.",
    "நைட்ரஜன் உரத்தை அதிகம் இடாதீர்கள்; பரிந்துரைத்த, எதிர்ப்புத் திறன் ரகங்கள், சுத்தமான விதை நெல் பயன்படுத்தவும். விவசாய சேவை மையத்திற்கு முன்கூட்டியே தெரிவிக்கவும் - சிகிச்சைக்கு நேரம் முக்கியம்."
  ]),
  PestEntry("bph", "🌾", ["Rice"], ["Brown planthopper (BPH)", "දුඹුරු පැල කීඩෑවා (බී.පී.එච්.)", "பழுப்பு தத்துப்பூச்சி"], [
    "Circular patches where plants dry up and turn yellow-brown, as if burnt (\"hopper burn\"). Small brown insects at the base of the plants, just above the water.",
    "පැළ වියළී කහ-දුඹුරු වී පිච්චුනා සේ වට්ටාකාර පැල්ලම් ('හොපර් බර්න්'). ජල මට්ටමට ඉහළින් පැළ පාමුල කුඩා දුඹුරු කෘමීන්.",
    "செடிகள் காய்ந்து மஞ்சள்-பழுப்பாகி எரிந்தது போல வட்டத் திட்டுகள். நீர்மட்டத்திற்கு மேல் அடிப்பகுதியில் சிறு பழுப்புப் பூச்சிகள்."
  ], [
    "Avoid too much nitrogen and very dense sowing; do not spray insecticides without advice - they kill the natural enemies and make the hoppers multiply. Check the base of plants weekly and report early to your Agrarian Service Centre.",
    "නයිට්‍රජන් අධික භාවිතය හා ඝන වපුරීම වළක්වන්න; උපදෙස් නැතිව කෘමිනාශක නොඉසින්න - ස්වාභාවික සතුරන් මිය ගොස් කීඩෑවන් වැඩි වේ. සතියකට වරක් පැළ පාමුල බලා ගොවිජන සේවා මධ්‍යස්ථානයට කල් තියා දන්වන්න.",
    "அதிக நைட்ரஜன், அடர்ந்த விதைப்பைத் தவிர்க்கவும்; ஆலோசனையின்றி பூச்சிக்கொல்லி தெளிக்காதீர்கள் - இயற்கை எதிரிகள் அழிந்து தத்துப்பூச்சி பெருகும். வாரம் ஒருமுறை அடிப்பகுதியைப் பார்த்து சேவை மையத்திற்குத் தெரிவிக்கவும்."
  ]),
  PestEntry("fall_armyworm", "🌽", ["Maize"], ["Fall armyworm (Sena caterpillar)", "සේනා දළඹුවා", "படைப்புழு"], [
    "Ragged holes and 'windows' in young leaves, sawdust-like droppings in the whorl of the plant, caterpillars hiding in the whorl.",
    "ළපටි කොළ වල සිදුරු හා 'ජනෙල්', පැළයේ මැද කුඩු වැනි අපද්‍රව්‍ය, මැද සැඟවුණු දළඹුවන්.",
    "இளம் இலைகளில் ஒழுங்கற்ற துளைகள், செடியின் நடுவில் மரத்தூள் போன்ற கழிவு, உள்ளே புழுக்கள்."
  ], [
    "Walk the field early in the morning and look in the whorls of young plants. Crush egg masses and small caterpillars by hand where the area is small. Tell your Agrarian Service Centre quickly - young caterpillars are easiest to control.",
    "උදෑසන කුඹුර පරීක්ෂා කර ළපටි පැළ වල මැද බලන්න. කුඩා ප්‍රදේශයක නම් බිත්තර පොකුරු හා කුඩා දළඹුවන් අතින් මරන්න. ගොවිජන සේවා මධ්‍යස්ථානයට ඉක්මනින් දන්වන්න - කුඩා දළඹුවන් පාලනය පහසුයි.",
    "அதிகாலையில் வயலைப் பார்த்து இளம் செடிகளின் நடுவைச் சோதிக்கவும். சிறிய பரப்பில் முட்டைக் குவியல், சிறு புழுக்களை கையால் நசுக்கவும். சேவை மையத்திற்கு விரைவில் தெரிவிக்கவும் - சிறு புழுக்களைக் கட்டுப்படுத்துவது எளிது."
  ]),
  PestEntry("rhino_beetle", "🥥", ["Coconut"], ["Coconut rhinoceros beetle", "පොල් රයිනෝ කුරුමිණියා", "தென்னை காண்டாமிருக வண்டு"], [
    "V-shaped cuts in the fronds and chewed fibre pushed out of holes at the crown of the palm.",
    "අතු වල V හැඩැති කැපුම් හා ගසේ මුදුනේ සිදුරු වලින් එළියට එන ලෙලි කුඩු.",
    "ஓலைகளில் V வடிவ வெட்டுகள்; மரத்தின் உச்சியில் துளைகளிலிருந்து மெல்லப்பட்ட நார்."
  ], [
    "Clean up the places the beetles breed: rotting coconut logs, compost heaps, sawdust. Remove grubs found there. Ask your Coconut Development Authority officer about traps and other control.",
    "කුරුමිණියන් බෝවන ස්ථාන පිරිසිදු කරන්න: කුණු වන පොල් කඳන්, කොම්පෝස්ට් ගොඩවල්, දර කුඩු. එහි ඇති කීටයන් ඉවත් කරන්න. උගුල් හා අනෙකුත් පාලන ක්‍රම ගැන පොල් සංවර්ධන අධිකාරියේ නිලධාරියාගෙන් අසන්න.",
    "வண்டுகள் முட்டையிடும் இடங்களைச் சுத்தம் செய்யவும்: அழுகும் தென்னை மரக்கட்டைகள், உரக்குவியல், மரத்தூள். அங்குள்ள புழுக்களை அகற்றவும். பொறிகள் பற்றி தென்னை அபிவிருத்தி அதிகாரசபை அலுவலரிடம் கேளுங்கள்."
  ]),
  PestEntry("panama_wilt", "🍌", ["Banana"], ["Panama wilt (Fusarium)", "පැනමා මැළවීම", "பனாமா வாடல்"], [
    "Older leaves turn yellow and hang down around the stem; the base of the trunk may split; cut trunk shows brown-red streaks inside.",
    "පැරණි කොළ කහ වී කඳ වටා එල්ලේ; කඳ පාමුල පැලෙන්නට පුළුවන්; කැපූ කඳ ඇතුළත දුඹුරු-රතු ඉරි.",
    "பழைய இலைகள் மஞ்சளாகி தண்டைச் சுற்றித் தொங்கும்; அடிப்பகுதி பிளக்கலாம்; வெட்டினால் உள்ளே பழுப்பு-சிவப்பு கோடுகள்."
  ], [
    "The disease lives in the soil. Plant only clean, healthy suckers or tissue-culture plants, do not carry soil or suckers from sick fields, and remove sick plants. Report it to your Agrarian Service Centre.",
    "රෝගය පසේ ජීවත් වේ. පිරිසිදු, නිරෝගී පැළ හෝ පටක රෝපිත පැළ පමණක් සිටුවන්න, රෝගී කුඹුරුවලින් පස් හෝ පැළ රැගෙන නොයන්න, රෝගී පැළ ඉවත් කරන්න. ගොවිජන සේවා මධ්‍යස්ථානයට දන්වන්න.",
    "நோய் மண்ணில் வாழும். சுத்தமான, ஆரோக்கியமான கன்றுகள் அல்லது திசு வளர்ப்புச் செடிகளையே நடவும்; நோயுற்ற தோட்டத்திலிருந்து மண்/கன்றுகளை எடுத்துச் செல்லாதீர்கள்; நோயுற்ற செடிகளை அகற்றவும். சேவை மையத்திற்குத் தெரிவிக்கவும்."
  ]),
];
