import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/app_locale.dart';
import '../localization/tr.dart';
import '../services/insights_api.dart';
import '../theme/app_theme.dart';
import '../widgets/credit_score_gauge.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/ui_kit.dart';

/// FARM PASSPORT — a one-page track record the farmer can show a lender or
/// investor, with a QR code that opens the same page on any phone (no app or
/// login needed). Built only from what AgriLink has recorded.
class FarmPassportScreen extends StatefulWidget {
  const FarmPassportScreen({super.key});

  @override
  State<FarmPassportScreen> createState() => _FarmPassportScreenState();
}

class _FarmPassportScreenState extends State<FarmPassportScreen> {
  Map<String, dynamic>? _passport;
  String _shareUrl = "";
  String _qrUrl = "";
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await InsightsApi.getMyPassport();
    if (!mounted) return;
    if (result["success"] == true && result["data"] is Map) {
      final data = Map<String, dynamic>.from(result["data"] as Map);
      setState(() {
        _passport = Map<String, dynamic>.from(data["passport"] as Map);
        _shareUrl = "${data["shareUrl"]}";
        _qrUrl = "${data["qrUrl"]}";
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _error = result["message"]?.toString() ?? tr("Could not load your passport.", "ඔබේ පාස්පෝට් එක පූරණය කළ නොහැකි විය.", "உங்கள் பாஸ்போர்ட்டை ஏற்ற முடியவில்லை.");
      });
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _shareUrl));
    _toast(tr("Link copied. Paste it into WhatsApp or email.", "සබැඳිය පිටපත් කළා. WhatsApp හෝ ඊමේල් වෙත අලවන්න.", "இணைப்பு நகலெடுக்கப்பட்டது. WhatsApp அல்லது மின்னஞ்சலில் ஒட்டுங்கள்."));
  }

  Future<void> _openPage() async {
    final uri = Uri.parse(_shareUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _rotate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(tr("Replace your link?", "ඔබේ සබැඳිය වෙනස් කරන්නද?", "உங்கள் இணைப்பை மாற்றவா?")),
        content: Text(tr(
          "A new link and QR code will be created. Anything you shared before will stop working straight away.",
          "නව සබැඳියක් සහ QR කේතයක් සාදනු ලැබේ. ඔබ කලින් බෙදාගත් සියල්ල වහාම ක්‍රියා නොකරනු ඇත.", "புதிய இணைப்பும் QR குறியீடும் உருவாக்கப்படும். நீங்கள் முன்பு பகிர்ந்தவை உடனே செயலிழக்கும்.",
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr("Cancel", "අවලංගු", "ரத்து செய்"))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(tr("Replace", "වෙනස් කරන්න", "மாற்று"))),
        ],
      ),
    );
    if (ok != true) return;
    final result = await InsightsApi.rotatePassportLink();
    _toast(result["message"]?.toString() ?? tr("Done.", "සම්පූර්ණයි.", "முடிந்தது."));
    _load();
  }

  Widget _tile(String value, String label, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: tintOf(context, accent), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: accent)),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 11.5, color: mutedOf(context))),
        ],
      ),
    );
  }

  Widget _grid(List<Widget> tiles) {
    final rows = <Widget>[];
    for (int i = 0; i < tiles.length; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(child: tiles[i]),
            const SizedBox(width: 10),
            Expanded(child: i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink()),
          ],
        ),
      ));
    }
    return Column(children: rows);
  }

  // Localised text for each readiness check (the server sends English).
  static const Map<String, List<String>> _readinessText = {
    "cycles": ["Complete 2 crop cycles", "වගා වට 2ක් සම්පූර්ණ කරන්න", "Finish a crop timeline (or repay a funded campaign) to add a completed cycle.", "වගා කාලසටහනක් අවසන් කරන්න (හෝ අරමුදල් ලද ව්‍යාපෘතියක් ආපසු ගෙවන්න).", "2 பயிர் சுழற்சிகளை நிறைவு செய்யுங்கள்", "ஒரு பயிர் காலவரிசையை முடிக்கவும் (அல்லது நிதி பெற்ற திட்டத்தைத் திருப்பிச் செலுத்தவும்)."],
    "sales": ["Make 5 completed sales", "සම්පූර්ණ විකුණුම් 5ක් කරන්න", "List produce on the marketplace and mark orders as sold.", "වෙළඳපොළේ අස්වැන්න ලැයිස්තුගත කර ඇණවුම් විකුණා ඇති බව සලකුණු කරන්න.", "5 விற்பனைகளை முடியுங்கள்", "சந்தையில் விளைபொருளைப் பட்டியலிட்டு, ஆர்டர்களை விற்றதாகக் குறியுங்கள்."],
    "volume": ["Reach LKR 100,000 in total sales", "මුළු විකුණුම් රු. 100,000 කට ළඟා වන්න", "Sell more produce, or join Group Lots to reach bulk buyers.", "තවත් අස්වැන්න විකුණන්න, නැතහොත් තොග ගැනුම්කරුවන් වෙත ළඟා වීමට කණ්ඩායම් ලොට් වලට එක්වන්න.", "மொத்த விற்பனை LKR 100,000 ஐ எட்டுங்கள்", "மேலும் விளைபொருளை விற்கவும், அல்லது மொத்த வாங்குபவர்களை எட்ட குழுத் தொகுப்புகளில் சேரவும்."],
    "quality": ["Keep buyer rejections at 20% or less", "ගැනුම්කරු ප්‍රතික්ෂේප 20% හෝ ඊට අඩුවෙන් තබන්න", "Grade and pack produce carefully; sell while it is still fresh.", "අස්වැන්න ශ්‍රේණිගත කර සෝදුවලින් පුරවන්න; නැවුම්ව තිබියදී විකුණන්න.", "வாங்குபவர் நிராகரிப்பை 20% அல்லது அதற்குக் கீழ் வையுங்கள்", "விளைபொருளை கவனமாகத் தரம் பிரித்து அடுக்குங்கள்; புதியதாக இருக்கும்போதே விற்கவும்."],
    "repayment": ["Repay one funding campaign", "අරමුදල් ව්‍යාපෘතියක් ආපසු ගෙවන්න", "Ask investors to fund a crop, then repay after harvest.", "ආයෝජකයන්ගෙන් බෝගයකට අරමුදල් ඉල්ලා, අස්වැන්නෙන් පසු ආපසු ගෙවන්න.", "ஒரு நிதித் திட்டத்தைத் திருப்பிச் செலுத்துங்கள்", "முதலீட்டாளர்களிடம் பயிருக்கு நிதி கேளுங்கள், அறுவடைக்குப் பின் திருப்பிச் செலுத்துங்கள்."],
    "score": ["Reach a credit score of 600", "ණය ලකුණු 600 කට ළඟා වන්න", "The score grows with completed cycles and repaid funding.", "සම්පූර්ණ කළ වට සහ ආපසු ගෙවූ අරමුදල් සමඟ ලකුණු වැඩි වේ.", "கடன் மதிப்பெண் 600 ஐ எட்டுங்கள்", "நிறைவு செய்த சுழற்சிகள் மற்றும் திருப்பிச் செலுத்திய நிதியுடன் மதிப்பெண் உயரும்."],
    "community": ["Complete one group sale", "කණ්ඩායම් විකුණුමක් සම්පූර්ණ කරන්න", "Join a Group Lot in the Market tab and wait for a buyer to claim it.", "වෙළඳපොළ ටැබ් එකේ කණ්ඩායම් ලොට් එකකට එක්වී ගැනුම්කරුවෙකු එය ගන්නා තුරු බලා සිටින්න.", "ஒரு குழு விற்பனையை முடியுங்கள்", "சந்தை தாவலில் ஒரு குழுத் தொகுப்பில் சேர்ந்து, வாங்குபவர் எடுத்துக்கொள்ளும் வரை காத்திருங்கள்."],
    "history": ["Be active for 60 days", "දින 60ක් සක්‍රියව සිටින්න", "A longer record builds trust; keep using AgriLink.", "දිගු වාර්තාවක් විශ්වාසය ගොඩනඟයි; AgriLink භාවිත කරමින් සිටින්න.", "60 நாட்கள் செயலில் இருங்கள்", "நீண்ட பதிவு நம்பிக்கையை உருவாக்கும்; AgriLink ஐத் தொடர்ந்து பயன்படுத்துங்கள்."],
  };

  /// LOAN READINESS: how close the farmer is to what lenders like to see.
  Widget _readinessCard(Map<String, dynamic> readiness) {
    final percent = numOf(readiness["percent"]);
    final level = "${readiness["level"]}";
    final passed = (readiness["passed"] as num?)?.toInt() ?? 0;
    final total = (readiness["total"] as num?)?.toInt() ?? 0;
    final checks = (readiness["checks"] as List? ?? []).map((c) => Map<String, dynamic>.from(c as Map)).toList();

    final Color color = level == "loan_ready" ? AppColors.forest : level == "almost_ready" ? AppColors.gold : AppColors.indigo;
    final String levelLabel = level == "loan_ready"
        ? tr("Loan-ready", "ණය සඳහා සූදානම්", "கடனுக்குத் தயார்")
        : level == "almost_ready"
            ? tr("Almost ready", "සූදානම් වෙමින්", "கிட்டத்தட்ட தயார்")
            : tr("Getting started", "ආරම්භක අවස්ථාව", "தொடக்க நிலை");

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, size: 18, color: AppColors.forest),
              const SizedBox(width: 8),
              Expanded(child: Text(tr("Loan readiness", "ණය සූදානම", "கடன் தயார்நிலை"), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
              StatusPill(label: levelLabel, color: color),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("$passed", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: color)),
              Padding(
                padding: const EdgeInsets.only(bottom: 5, left: 4),
                child: Text(tr("of $total checks", "චෙක් $total න්", "$total சோதனைகளில்"), style: TextStyle(fontSize: 13, color: mutedOf(context))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RoundedBar(value: percent / 100, color: color, height: 10),
          const SizedBox(height: 14),
          ...checks.map((c) {
            final met = c["met"] == true;
            final id = "${c["id"]}";
            final text = _readinessText[id];
            final label = text != null ? tr(text[0], text[1], text[4]) : "${c["label"]}";
            final tip = text != null ? tr(text[2], text[3], text[5]) : "${c["tip"]}";
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 20, color: met ? AppColors.forest : mutedOf(context)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          met ? label : "$label  (${groupedNumber(numOf(c["current"]))}/${groupedNumber(numOf(c["target"]))})",
                          style: TextStyle(fontSize: 13.5, fontWeight: met ? FontWeight.w600 : FontWeight.w700, color: inkOf(context)),
                        ),
                        if (!met) Text(tip, style: TextStyle(fontSize: 12, color: mutedOf(context), height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          Text(
            tr("This is AgriLink's own checklist to guide you. It is not a bank's criteria and not a credit decision.",
                "මෙය ඔබට මග පෙන්වීමට AgriLink හි ම චෙක්ලිස්ට් එකකි. එය බැංකුවක නිර්ණායක හෝ ණය තීරණයක් නොවේ.", "இது உங்களுக்கு வழிகாட்ட AgriLink இன் சொந்தச் சரிபார்ப்புப் பட்டியல். இது வங்கியின் அளவுகோல் அல்ல, கடன் முடிவும் அல்ல."),
            style: TextStyle(fontSize: 11, color: mutedOf(context), height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _body(Map<String, dynamic> passport) {
    final t = AppLocale.instance.t;
    final stats = Map<String, dynamic>.from(passport["stats"] as Map);
    final score = (passport["creditScore"] as num?)?.toInt() ?? 500;
    final scoreLabel = score >= 800
        ? t("creditScoreExcellent")
        : score >= 600
            ? t("creditScoreGood")
            : t("creditScoreBuilding");
    final crops = (stats["cropsSold"] as List? ?? []).map((c) => "$c").toList();
    final readiness = passport["readiness"] is Map ? Map<String, dynamic>.from(passport["readiness"] as Map) : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.forestDark, AppColors.forest], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AGRILINK · ${tr("FARM PASSPORT", "ගොවි පාස්පෝට්", "பண்ணை பாஸ்போர்ட்").toUpperCase()}", style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text("${passport["name"]}", style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text("${passport["district"]}".isEmpty ? "Sri Lanka" : "${passport["district"]}", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text("${passport["passportId"]}", style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: "monospace")),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          delayMs: 80,
          child: SoftCard(
            child: Column(
              children: [
                CreditScoreGauge(score: score, label: scoreLabel),
                const SizedBox(height: 6),
                Text(t("creditScore"), style: TextStyle(fontSize: 12.5, color: mutedOf(context), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        if (readiness != null) FadeSlideIn(delayMs: 110, child: _readinessCard(readiness)),
        FadeSlideIn(
          delayMs: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: tr("Farming record", "වගා වාර්තාව", "விவசாயப் பதிவு")),
              _grid([
                _tile("${stats["completedTimelines"]}", tr("Crop cycles completed", "සම්පූර්ණ කළ වගා වට", "நிறைவு செய்த பயிர் சுழற்சிகள்"), AppColors.forest),
                _tile("${stats["activeTimelines"]}", tr("Growing now", "දැන් වගා කරන", "இப்போது வளர்பவை"), AppColors.forest),
              ]),
              SectionHeader(title: tr("Sales on AgriLink", "AgriLink හි විකුණුම්", "AgriLink இல் விற்பனைகள்")),
              _grid([
                _tile("${stats["salesCompleted"]}", tr("Completed sales", "සම්පූර්ණ විකුණුම්", "முடிந்த விற்பனைகள்"), AppColors.forest),
                _tile("${groupedNumber(numOf(stats["kgSold"]))} kg", tr("Produce sold", "විකුණූ අස්වැන්න", "விற்ற விளைபொருள்"), AppColors.forest),
                _tile(lkr(numOf(stats["salesValueLkr"])), tr("Total sales value", "මුළු විකුණුම් වටිනාකම", "மொத்த விற்பனை மதிப்பு"), AppColors.gold),
                _tile("${stats["buyerRejectionRatePercent"]}%", tr("Rejected by buyers", "ගැනුම්කරුවන් ප්‍රතික්ෂේප කළ", "வாங்குபவர்கள் நிராகரித்தவை"), AppColors.indigo),
              ]),
              if (crops.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text("${tr("Crops sold", "විකුණූ බෝග", "விற்ற பயிர்கள்")}: ${crops.join(", ")}", style: TextStyle(fontSize: 12.5, color: mutedOf(context), height: 1.4)),
                ),
              SectionHeader(title: tr("Funding & repayment", "අරමුදල් සහ ආපසු ගෙවීම", "நிதி & திருப்பிச் செலுத்துதல்")),
              _grid([
                _tile("${stats["fundingCampaignsFunded"]}", tr("Campaigns funded", "අරමුදල් ලැබූ ව්‍යාපෘති", "நிதி பெற்ற திட்டங்கள்"), AppColors.forest),
                _tile(lkr(numOf(stats["fundingRaisedLkr"])), tr("Raised from investors", "ආයෝජකයන්ගෙන් ලැබුණු", "முதலீட்டாளர்களிடமிருந்து திரட்டியது"), AppColors.gold),
                _tile("${stats["fundingRepaidCampaigns"]}", tr("Campaigns repaid", "ආපසු ගෙවූ ව්‍යාපෘති", "திருப்பிச் செலுத்திய திட்டங்கள்"), AppColors.forest),
                _tile(lkr(numOf(stats["fundingRepaidLkr"])), tr("Repaid to investors", "ආයෝජකයන්ට ගෙවූ", "முதலீட்டாளர்களுக்குச் செலுத்தியது"), AppColors.gold),
              ]),
              SectionHeader(title: tr("Community", "ප්‍රජාව", "சமூகம்")),
              _grid([
                _tile("${stats["groupSalesCompleted"]}", tr("Group sales", "කණ්ඩායම් විකුණුම්", "குழு விற்பனைகள்"), AppColors.indigo),
                _tile("${groupedNumber(numOf(stats["groupKgContributed"]))} kg", tr("Contributed to lots", "ලොට් වලට දායක කළ", "தொகுப்புகளுக்கு வழங்கியது"), AppColors.indigo),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SectionHeader(
          title: tr("Share it", "බෙදාගන්න", "பகிருங்கள்"),
          subtitle: tr("Anyone can scan this QR code to open your passport page. No app or login needed.", "ඕනෑම කෙනෙකුට මෙම QR කේතය ස්කෑන් කර ඔබේ පාස්පෝට් පිටුව විවෘත කළ හැක. යෙදුමක් හෝ ලොග් වීමක් අවශ්‍ය නැත.", "யார் வேண்டுமானாலும் இந்த QR குறியீட்டை ஸ்கேன் செய்து உங்கள் பாஸ்போர்ட் பக்கத்தைத் திறக்கலாம். செயலியோ உள்நுழைவோ தேவையில்லை."),
        ),
        SoftCard(
          child: Column(
            children: [
              Container(
                width: 190,
                height: 190,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderOf(context))),
                child: Image.network(
                  _qrUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  errorBuilder: (context, error, stack) => Center(
                    child: Text(tr("QR code could not load. Check your connection.", "QR කේතය පූරණය නොවීය. සම්බන්ධතාව පරීක්ෂා කරන්න.", "QR குறியீட்டை ஏற்ற முடியவில்லை. இணைப்பைச் சரிபார்க்கவும்."), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _copyLink,
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: Text(tr("Copy link", "සබැඳිය පිටපත් කරන්න", "இணைப்பை நகலெடு")),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openPage,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: Text(tr("Open page", "පිටුව විවෘත කරන්න", "பக்கத்தைத் திற")),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _rotate,
                icon: const Icon(Icons.autorenew_rounded, size: 16, color: AppColors.danger),
                label: Text(tr("Replace link (stops old links)", "සබැඳිය වෙනස් කරන්න (පැරණි සබැඳි නවතී)", "இணைப்பை மாற்று (பழைய இணைப்புகள் நின்றுவிடும்)"), style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
              ),
            ],
          ),
        ),
        InfoBanner(
          icon: Icons.info_outline_rounded,
          color: AppColors.gold,
          text: tr(
            "Sales, funding and repayment are recorded from activity on AgriLink. Crop timelines are entered by you and are not independently checked. This passport supports a loan or investment request but does not replace a lender's own checks.",
            "විකුණුම්, අරමුදල් සහ ආපසු ගෙවීම් AgriLink ක්‍රියාකාරකම් වලින් සටහන් වේ. වගා කාලසටහන් ඔබ විසින් ඇතුළත් කරන අතර ස්වාධීනව පරීක්ෂා නොකෙරේ. මෙම පාස්පෝට් එක ණය හෝ ආයෝජන ඉල්ලීමකට සහාය වන නමුත් ණය දෙන්නාගේ තමන්ගේම පරීක්ෂාවන් ප්‍රතිස්ථාපනය නොකරයි.", "விற்பனை, நிதி மற்றும் திருப்பிச் செலுத்துதல் AgriLink செயல்பாடுகளிலிருந்து பதிவாகின்றன. பயிர் காலவரிசைகளை நீங்களே உள்ளிடுகிறீர்கள்; அவை தனியாகச் சரிபார்க்கப்படுவதில்லை. இந்த பாஸ்போர்ட் கடன் அல்லது முதலீட்டுக் கோரிக்கைக்கு ஆதரவாக இருக்கும், ஆனால் கடன் வழங்குபவரின் சொந்தச் சரிபார்ப்புகளுக்கு மாற்றாகாது.",
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        Widget content;
        if (_loading) {
          content = ListView(padding: const EdgeInsets.all(16), children: const [ShimmerCard(), ShimmerCard(), ShimmerCard()]);
        } else if (_error != null || _passport == null) {
          content = Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.inkMuted),
                  const SizedBox(height: 12),
                  Text(_error ?? "", textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: Text(tr("Try again", "නැවත උත්සාහ කරන්න", "மீண்டும் முயற்சிக்கவும்"))),
                ],
              ),
            ),
          );
        } else {
          content = _body(_passport!);
        }
        return Scaffold(
          appBar: AppBar(title: Text(tr("Farm Passport", "ගොවි පාස්පෝට්", "பண்ணை பாஸ்போர்ட்"))),
          body: content,
        );
      },
    );
  }
}
