import 'package:flutter/material.dart';
import '../localization/tr.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../services/session_events.dart';
import 'smooth_route.dart';

/// Wrap a signed-in screen with this. If the server ever answers "your login
/// has expired", the app signs out and returns to the login screen with a
/// clear message — instead of leaving broken, half-loaded screens.
class SessionGuard extends StatefulWidget {
  final Widget child;
  const SessionGuard({super.key, required this.child});

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    SessionEvents.expired.addListener(_onExpired);
  }

  @override
  void dispose() {
    SessionEvents.expired.removeListener(_onExpired);
    super.dispose();
  }

  Future<void> _onExpired() async {
    if (_handling || !mounted) return;
    _handling = true;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await AuthService.logout();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(SmoothRoute(page: const LoginScreen()), (route) => false);
    messenger.showSnackBar(SnackBar(content: Text(tr("Your session ended. Please log in again.", "ඔබේ සැසිය අවසන් විය. කරුණාකර නැවත ඇතුළු වන්න.", "உங்கள் அமர்வு முடிந்தது. மீண்டும் உள்நுழையுங்கள்."))));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
