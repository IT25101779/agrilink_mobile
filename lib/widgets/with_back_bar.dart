import 'package:flutter/material.dart';

/// Gives a page that normally lives inside the main tabs (no top bar of its
/// own) a proper top bar with a BACK arrow, for when it is opened as a
/// separate screen — e.g. from Simple mode. iPhones have no hardware back
/// button, so every opened screen must have this arrow.
class WithBackBar extends StatelessWidget {
  final String title;
  final Widget child;
  const WithBackBar({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(title),
      ),
      body: child,
    );
  }
}
