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
                          CircleAvatar(
                            radius: 34,
                            backgroundColor: AppColors.forestLight,
                            child: Text(
                              (_user?["fullName"] as String? ?? "?").substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.forest),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(_user?["fullName"] ?? "", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                          if (district != null)
                            Text(district, style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
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
                              trailing: TextButton(
                                onPressed: () => AppLocale.instance.setLanguage(AppLocale.instance.languageCode == "en" ? "si" : "en"),
                                child: Text(AppLocale.instance.languageCode == "en" ? "English" : "සිංහල"),
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
