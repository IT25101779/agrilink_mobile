import 'package:flutter/material.dart';

/// Drop-in replacement for MaterialPageRoute that fades and slides the new
/// screen in from below, instead of the default abrupt platform transition.
class SmoothRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 220),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
                child: child,
              ),
            );
          },
        );
}
