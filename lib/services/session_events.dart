import 'package:flutter/foundation.dart';

/// Lets the network layer tell the rest of the app "the server says your login has expired".
/// Screens never handle this themselves — SessionGuard listens and returns to the login screen.
class SessionEvents {
  static final ValueNotifier<int> expired = ValueNotifier<int>(0);

  static void notifyExpired() => expired.value = expired.value + 1;
}
