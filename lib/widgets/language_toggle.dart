import 'package:flutter/material.dart';
import '../localization/app_locale.dart';

/// Compact EN / සිං toggle, meant to sit in an AppBar's actions.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final isEnglish = AppLocale.instance.languageCode == "en";
        return GestureDetector(
          onTap: () => AppLocale.instance.setLanguage(isEnglish ? "si" : "en"),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  isEnglish ? "EN" : "සිං",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
