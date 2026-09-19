import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'crop_navigator_screen.dart';
import 'timeline_list_screen.dart';
import 'market_hub_screen.dart';
import 'disease_scanner_screen.dart';
import 'logistics_screen.dart';
import 'chat_screen.dart';
import 'reminders_screen.dart';
import 'login_screen.dart';
import '../models/timeline_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/reminder_engine.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_locale.dart';
import '../widgets/smooth_route.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/language_toggle.dart';
import '../widgets/theme_toggle.dart';
import 'profile_screen.dart';
import '../localization/tr.dart';
import 'chat_hub_screen.dart';

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
    MarketHubScreen(),
    ChatHubScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _pullTimelinesOnOpen();
    _refreshReminders();
  }

  Future<void> _loadUserName() async {
    final name = await AuthService.getUserName();
    setState(() => _userName = name ?? "");
  }

  /// Downloads any timelines that exist on the backend but not on this
  /// device yet — created on another device, or from before a reinstall.
  /// Runs quietly on every Home screen open; the Timeline list re-renders
  /// automatically via Hive's box.listenable() the moment anything new
  /// gets written, so there's no loading state to manage here.
  Future<void> _pullTimelinesOnOpen() async {
    final box = Hive.box<TimelineModel>("timelines");
    await SyncService.pullRemoteTimelines(box: box);
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
        final titles = [t("myTimelines"), t("cropNavigator"), t("diseaseScanner"), t("logistics"), t("marketplace"), tr("Community", "ප්‍රජාව", "சமூகம்")];
        final navItems = [
          NavItem(Icons.checklist_rounded, t("timelines")),
          NavItem(Icons.explore_rounded, t("navigator")),
          NavItem(Icons.biotech_rounded, t("scanner")),
          NavItem(Icons.local_shipping_rounded, t("logistics")),
          NavItem(Icons.storefront_rounded, t("market")),
          NavItem(Icons.forum_rounded, tr("Community", "ප්‍රජාව", "சமூகம்")),
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
                    tooltip: tr("Reminders", "මතක් කිරීම්", "நினைவூட்டல்கள்"),
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
              tooltip: tr("Ask the Agri Assistant", "කෘෂි සහායකයාගෙන් අහන්න", "விவசாய உதவியாளரிடம் கேளுங்கள்"),
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
