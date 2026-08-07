import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'crop_navigator_screen.dart';
import 'timeline_list_screen.dart';
import 'marketplace_screen.dart';
import 'disease_scanner_screen.dart';
import 'logistics_screen.dart';
import 'chat_screen.dart';
import 'reminders_screen.dart';
import 'login_screen.dart';
import '../models/timeline_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/reminder_engine.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/smooth_route.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/language_toggle.dart';
import '../widgets/theme_toggle.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = "";
  int _pendingReminderCount = 0;

  final List<Widget> _screens = const [
    TimelineListScreen(),
    CropNavigatorScreen(),
    DiseaseScannerScreen(),
    LogisticsScreen(),
    MarketplaceScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _refreshReminders();
  }

  Future<void> _loadUserName() async {
    final name = await AuthService.getUserName();
    setState(() => _userName = name ?? "");
  }

  Future<void> _refreshReminders() async {
    final timelineBox = Hive.box<TimelineModel>("timelines");
    await ReminderEngine.refreshAndNotify(timelineBox);

    final farmerId = await AuthService.getUserId();
    if (farmerId == null) return;
    final result = await ApiService.getReminders(farmerId, status: "pending");
    if (result["success"] == true && mounted) {
      setState(() => _pendingReminderCount = (result["data"] as List).length);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, SmoothRoute(page: const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final t = AppLocale.instance.t;
        final titles = [t("myTimelines"), t("cropNavigator"), t("diseaseScanner"), t("logistics"), t("marketplace")];
        final navItems = [
          NavItem(Icons.checklist_rounded, t("timelines")),
          NavItem(Icons.explore_rounded, t("navigator")),
          NavItem(Icons.biotech_rounded, t("scanner")),
          NavItem(Icons.local_shipping_rounded, t("logistics")),
          NavItem(Icons.storefront_rounded, t("market")),
        ];

        return Scaffold(
          extendBody: true,
          appBar: AppBar(
            title: Text(titles[_selectedIndex]),
            actions: [
              const ThemeToggle(),
              const LanguageToggle(),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded),
                    tooltip: "Reminders",
                    onPressed: () => Navigator.push(context, SmoothRoute(page: const RemindersScreen())).then((_) => _refreshReminders()),
                  ),
                  if (_pendingReminderCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          "$_pendingReminderCount",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.person_rounded),
                tooltip: t("profile"),
                onPressed: () => Navigator.push(context, SmoothRoute(page: const ProfileScreen())).then((_) => _refreshReminders()),
              ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: Container(key: ValueKey(_selectedIndex), child: _screens[_selectedIndex]),
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 74),
            child: FloatingActionButton(
              tooltip: "Ask the Agri Assistant",
              backgroundColor: AppColors.gold,
              onPressed: () => Navigator.push(context, SmoothRoute(page: const ChatScreen())),
              child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: FloatingNavBar(
            items: navItems,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
          ),
        );
      },
    );
  }
}
