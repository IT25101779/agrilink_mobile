import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';

class NavItem {
  final IconData icon;
  final String label;
  const NavItem(this.icon, this.label);
}

class FloatingNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingNavBar({super.key, required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final isDark = ThemeController.instance.isDark;
        final barColor = isDark ? AppColorsDark.surface : Colors.white;
        final selectedBg = isDark ? AppColorsDark.forestLight : AppColors.forestLight;

        return Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: barColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 18, offset: const Offset(0, 6)),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth / items.length;
              return Stack(
                children: [
                  // Continuously sliding pill behind the selected item —
                  // AnimatedPositioned tweens its position on every tap
                  // instead of each item independently recoloring.
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: itemWidth * currentIndex,
                    top: 0,
                    bottom: 0,
                    width: itemWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: DecoratedBox(decoration: BoxDecoration(color: selectedBg, borderRadius: BorderRadius.circular(16))),
                    ),
                  ),
                  Row(
                    children: List.generate(items.length, (index) {
                      final isSelected = index == currentIndex;
                      final item = items[index];
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            onTap(index);
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 280),
                                  curve: Curves.easeOutBack,
                                  scale: isSelected ? 1.12 : 1.0,
                                  child: Icon(item.icon, size: 21, color: isSelected ? AppColors.forest : AppColors.inkMuted),
                                ),
                                const SizedBox(height: 3),
                                AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 220),
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? AppColors.forest : AppColors.inkMuted,
                                  ),
                                  child: Text(item.label),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
