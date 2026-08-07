import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/language_toggle.dart';
import '../widgets/theme_toggle.dart';
import 'login_screen.dart';

class _OnboardPage {
  final IconData icon;
  final Color accent;
  final String titleKey;
  final String descKey;
  const _OnboardPage({required this.icon, required this.accent, required this.titleKey, required this.descKey});
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  static const _prefsKey = "has_seen_onboarding";

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardPage(icon: Icons.explore_rounded, accent: AppColors.forest, titleKey: "onboardTitle1", descKey: "onboardDesc1"),
    _OnboardPage(icon: Icons.biotech_rounded, accent: AppColors.danger, titleKey: "onboardTitle2", descKey: "onboardDesc2"),
    _OnboardPage(icon: Icons.storefront_rounded, accent: AppColors.gold, titleKey: "onboardTitle3", descKey: "onboardDesc3"),
    _OnboardPage(icon: Icons.volunteer_activism_rounded, accent: AppColors.indigo, titleKey: "onboardTitle4", descKey: "onboardDesc4"),
  ];

  Future<void> _finish() async {
    await OnboardingScreen.markSeen();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child),
      ),
    );
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        final isLast = _currentPage == _pages.length - 1;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: const [ThemeToggle(), LanguageToggle()]),
                      TextButton(onPressed: _finish, child: Text(t("skip"))),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return TweenAnimationBuilder<double>(
                        key: ValueKey(index),
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) => Opacity(
                          opacity: value,
                          child: Transform.translate(offset: Offset(0, (1 - value) * 24), child: child),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(color: page.accent.withOpacity(0.12), shape: BoxShape.circle),
                                child: Icon(page.icon, size: 64, color: page.accent),
                              ),
                              const SizedBox(height: 40),
                              Text(
                                t(page.titleKey),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                t(page.descKey),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14.5, color: AppColors.inkMuted, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive ? _pages[_currentPage].accent : AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(backgroundColor: _pages[_currentPage].accent),
                          child: Text(isLast ? t("getStarted") : t("next")),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
