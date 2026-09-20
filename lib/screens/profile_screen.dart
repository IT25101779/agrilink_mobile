import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/timeline_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import '../localization/app_locale.dart';
import '../widgets/credit_score_gauge.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/shimmer_loading.dart';
import 'login_screen.dart';
import 'farm_passport_screen.dart';
import '../localization/tr.dart';
import '../widgets/smooth_route.dart';
import '../widgets/user_avatar.dart';
import '../widgets/ui_kit.dart';
import 'edit_profile_screen.dart';
import 'orders_screen.dart';
import 'ledger_screen.dart';
import 'price_board_screen.dart';
import 'survey_screen.dart';
import 'return_trips_screen.dart';
import '../widgets/delivery_check_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final token = await AuthService.getToken();
    if (token != null) {
      final result = await ApiService.getCurrentUser(token);
      if (result["success"] == true && mounted) {
        setState(() => _user = result["data"]);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _confirmLogout() async {
    final t = AppLocale.instance.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(t("logout")),
        content: Text(t("logoutConfirm")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t("cancel"))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(t("logout")),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([AppLocale.instance, ThemeController.instance]),
      builder: (context, _) {
        final t = AppLocale.instance.t;
        final creditScore = (_user?["farmerProfile"]?["creditScore"] as num?)?.toInt() ?? 500;
        final completedCount = (_user?["farmerProfile"]?["completedTimelinesCount"] as num?)?.toInt() ?? 0;
        final district = _user?["farmerProfile"]?["district"] as String?;

        final scoreLabel = creditScore >= 800
            ? t("creditScoreExcellent")
            : creditScore >= 600
                ? t("creditScoreGood")
                : t("creditScoreBuilding");

        final timelineBox = Hive.box<TimelineModel>("timelines");
        final activeCount = timelineBox.values.where((tl) => tl.status == "active").length;

        return Scaffold(
          appBar: AppBar(title: Text(t("profile"))),
          body: _isLoading
              ? ListView(
                  padding: const EdgeInsets.all(16),
                  children: const [
                    Center(child: ShimmerBox(height: 160, width: 160, borderRadius: BorderRadius.all(Radius.circular(80)))),
                    SizedBox(height: 24),
                    ShimmerCard(),
                    ShimmerCard(),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    FadeSlideIn(
                      child: Column(
                        children: [
                          UserAvatar(
                            userId: _user?["_id"] as String?,
                            name: _user?["fullName"] as String? ?? "?",
                            size: 76,
                            hasPicture: _user?["avatarUpdatedAt"] != null,
                            version: "${_user?["avatarUpdatedAt"]}",
                          ),
                          const SizedBox(height: 10),
                          Text(_user?["fullName"] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          if (district != null)
                            Text(district, style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
                          TextButton.icon(
                            onPressed: () async {
                              final changed = await Navigator.push(context, SmoothRoute(page: const EditProfileScreen()));
                              if (changed == true) _load();
                            },
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: Text(tr("Edit profile", "පැතිකඩ සංස්කරණය", "சுயவிவரத்தைத் திருத்து")),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delayMs: 100,
                      child: Center(child: CreditScoreGauge(score: creditScore, label: scoreLabel)),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(t("creditScore"), style: const TextStyle(fontSize: 13, color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delayMs: 160,
                      child: Row(
                        children: [
                          Expanded(child: _statCard(t("activeTimelines"), "$activeCount", AppColors.forest)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard(t("completedTimelines"), "$completedCount", AppColors.gold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      delayMs: 190,
                      child: _passportCard(),
                    ),
                    if (_user?["role"] == "farmer") ...[
                      const SizedBox(height: 20),
                      FadeSlideIn(delayMs: 205, child: _toolsSection()),
                    ],
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delayMs: 220,
                      child: Text(t("settings"), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 10),
                    FadeSlideIn(
                      delayMs: 260,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: ThemeController.instance.isDark,
                              onChanged: (_) => ThemeController.instance.toggle(),
                              title: Text(t("darkMode")),
                              secondary: const Icon(Icons.dark_mode_rounded),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.translate_rounded),
                              title: Text(t("language")),
                              trailing: SegmentedButton<String>(
                                showSelectedIcon: false,
                                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                                segments: AppLocale.supportedCodes
                                    .map((code) => ButtonSegment<String>(value: code, label: Text(AppLocale.languageNames[code] ?? code, style: const TextStyle(fontSize: 12))))
                                    .toList(),
                                selected: {AppLocale.instance.languageCode},
                                onSelectionChanged: (selection) => AppLocale.instance.setLanguage(selection.first),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeSlideIn(
                      delayMs: 300,
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _confirmLogout,
                          icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                          label: Text(t("logout"), style: const TextStyle(color: AppColors.danger)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(child: Text(t("appVersion"), style: const TextStyle(fontSize: 11, color: AppColors.inkMuted))),
                  ],
                ),
        );
      },
    );
  }

  /// Entry point to the Farm Passport (shareable track record + QR code).
  Widget _toolTile(IconData icon, Color color, String label, VoidCallback onTap) {
    return SoftCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(children: [
        Container(width: 38, height: 38, decoration: BoxDecoration(color: tintOf(context, color), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
      ]),
    );
  }

  Widget _toolsSection() {
    void open(Widget page) => Navigator.push(context, SmoothRoute(page: page));
    final tiles = [
      _toolTile(Icons.receipt_long_rounded, const Color(0xFF0B5D3B), tr("My orders", "මගේ ඇණවුම්", "என் ஆர்டர்கள்"), () => open(const OrdersScreen())),
      _toolTile(Icons.account_balance_wallet_rounded, const Color(0xFF7C3AED), tr("Farm ledger", "ගොවිපල ගිණුම්", "பண்ணைக் கணக்கு"), () => open(const LedgerScreen())),
      _toolTile(Icons.show_chart_rounded, const Color(0xFFEA580C), tr("Price board", "මිල පුවරුව", "விலைப் பலகை"), () => open(const PriceBoardScreen())),
      _toolTile(Icons.local_shipping_rounded, const Color(0xFF2563EB), tr("Return-load deals", "ආපසු ගමන් දීමනා", "திரும்பும் லாரி சலுகைகள்"), () => open(const ReturnTripsScreen())),
      _toolTile(Icons.ac_unit_rounded, const Color(0xFF0E7490), tr("Delivery freshness", "බෙදාහැරීමේ නැවුම්බව", "விநியோகப் புத்துணர்ச்சி"), () => showDeliveryCheckSheet(context)),
      _toolTile(Icons.poll_rounded, const Color(0xFFB45309), tr("Quick surveys", "කෙටි සමීක්ෂණ", "விரைவு கருத்துக்கணிப்புகள்"), () => open(const SurveyScreen())),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr("Farm tools", "ගොවිපල මෙවලම්", "பண்ணைக் கருவிகள்"), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        GridView.count(crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.5, children: tiles),
      ],
    );
  }

  Widget _passportCard() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, SmoothRoute(page: const FarmPassportScreen())),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppColors.forestDark, AppColors.forest], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.verified_user_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr("Farm Passport", "ගොවි පාස්පෝට්", "பண்ணை பாஸ்போர்ட்"), style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      tr("Share your track record with lenders and investors", "ණය දෙන්නන් සහ ආයෝජකයන් සමඟ ඔබේ වාර්තාව බෙදාගන්න", "கடன் வழங்குவோர் மற்றும் முதலீட்டாளர்களுடன் உங்கள் சாதனைப் பதிவைப் பகிருங்கள்"),
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
