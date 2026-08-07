import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

/// Animated sun/moon toggle button for switching light/dark mode.
class ThemeToggle extends StatelessWidget {
  final Color? color;
  const ThemeToggle({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDark;
        return IconButton(
          tooltip: isDark ? "Switch to light mode" : "Switch to dark mode",
          onPressed: () => ThemeController.instance.toggle(),
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => RotationTransition(
              turns: Tween<double>(begin: 0.75, end: 1.0).animate(animation),
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              key: ValueKey(isDark),
              color: color,
            ),
          ),
        );
      },
    );
  }
}
