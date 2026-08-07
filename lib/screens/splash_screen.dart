import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import 'home_screen.dart';
import 'driver_home_screen.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool loggedIn;
  final String? role;

  const SplashScreen({super.key, required this.loggedIn, this.role});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacity = CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut));
    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1400), _navigateNext);
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;

    Widget destination;
    if (widget.loggedIn) {
      destination = widget.role == "driver" ? const DriverHomeScreen() : const HomeScreen();
    } else {
      final seenOnboarding = await OnboardingScreen.hasSeenOnboarding();
      destination = seenOnboarding ? const LoginScreen() : const OnboardingScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut), child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest,
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 44),
                ),
                const SizedBox(height: 20),
                Text(
                  AppLocale.instance.t("appName"),
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 6),
                Text(
                  AppLocale.instance.t("tagline"),
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
