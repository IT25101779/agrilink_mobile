import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/timeline_model.dart';
import 'models/milestone_model.dart';
import 'services/sync_service.dart';
import 'services/auth_service.dart';
import 'localization/app_locale.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TimelineModelAdapter());
  Hive.registerAdapter(MilestoneModelAdapter());

  final timelineBox = await Hive.openBox<TimelineModel>("timelines");

  // Start listening for connectivity changes so pending offline records
  // sync automatically the moment the device regains internet access.
  SyncService.listenAndAutoSync(timelineBox);

  await AppLocale.instance.loadSavedLanguage();
  await ThemeController.instance.loadSavedMode();

  final loggedIn = await AuthService.isLoggedIn();
  final role = loggedIn ? await AuthService.getUserRole() : null;

  runApp(AgriLinkApp(loggedIn: loggedIn, role: role));
}

class AgriLinkApp extends StatelessWidget {
  final bool loggedIn;
  final String? role;
  const AgriLinkApp({super.key, required this.loggedIn, this.role});

  @override
  Widget build(BuildContext context) {
    // Listens to both language and theme controllers — either one
    // changing rebuilds the whole app instantly.
    return ListenableBuilder(
      listenable: Listenable.merge([AppLocale.instance, ThemeController.instance]),
      builder: (context, _) {
        return MaterialApp(
          title: "AgriLink AI 2.0",
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.mode,
          home: SplashScreen(loggedIn: loggedIn, role: role),
        );
      },
    );
  }
}
