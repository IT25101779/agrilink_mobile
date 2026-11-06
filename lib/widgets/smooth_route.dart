import 'package:flutter/material.dart';

/// Page route used across the app. It is a normal platform route, so on iPhone
/// it slides in from the side AND supports the edge swipe-back gesture, and on
/// Android it uses the theme's page transition (see kPageTransitions).
/// (It used to be a custom fade route, which silently disabled iPhone swipe-back.)
class SmoothRoute<T> extends MaterialPageRoute<T> {
  SmoothRoute({required Widget page}) : super(builder: (_) => page);
}
