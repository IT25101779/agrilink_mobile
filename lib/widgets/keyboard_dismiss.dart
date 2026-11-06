import 'package:flutter/material.dart';
import '../localization/tr.dart';

/// Wraps the whole app (used from MaterialApp.builder) so that on EVERY screen:
///   1. tapping anywhere outside a text box closes the keyboard, and
///   2. while the keyboard is open, a slim "Done" bar sits right above it with
///      a button that moves the keyboard down (iPhones have no such button).
///
/// The page content is shrunk by the keyboard height plus the bar, so the bar
/// never covers a text box or a Send button.
class KeyboardDismissScope extends StatelessWidget {
  final Widget child;
  const KeyboardDismissScope({super.key, required this.child});

  static const double _barHeight = 44;

  static void hideKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final inset = mq.viewInsets.bottom;
    final showBar = inset > 0;

    // Keep the same widget structure whether or not the keyboard is open, so no
    // screen loses its state when the keyboard appears.
    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: Column(
        children: [
          Expanded(
            child: MediaQuery(
              data: showBar
                  ? mq.copyWith(
                      viewInsets: mq.viewInsets.copyWith(bottom: 0),
                      padding: mq.padding.copyWith(bottom: 0),
                      viewPadding: mq.viewPadding.copyWith(bottom: 0),
                    )
                  : mq,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: hideKeyboard,
                child: child,
              ),
            ),
          ),
          if (showBar) const _DoneBar(height: _barHeight),
        ],
      ),
    );
  }
}

class _DoneBar extends StatelessWidget {
  final double height;
  const _DoneBar({required this.height});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF232B25) : const Color(0xFFF1F4F1),
      elevation: 3,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: KeyboardDismissScope.hideKeyboard,
            icon: const Icon(Icons.keyboard_hide_rounded, size: 22),
            label: Text(
              tr("Done", "හරි", "முடிந்தது"),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: TextButton.styleFrom(foregroundColor: scheme.primary, padding: const EdgeInsets.symmetric(horizontal: 16)),
          ),
        ),
      ),
    );
  }
}
