import 'package:flutter/material.dart';
import '../localization/app_locale.dart';

/// Compact language picker (EN / සිං / த) that opens a small menu with all
/// three languages written in their own script. Sits in an AppBar's actions.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocale.instance,
      builder: (context, _) {
        final current = AppLocale.instance.languageCode;
        return PopupMenuButton<String>(
          tooltip: "Language",
          onSelected: AppLocale.instance.setLanguage,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          itemBuilder: (context) => AppLocale.supportedCodes
              .map(
                (code) => PopupMenuItem<String>(
                  value: code,
                  child: Row(
                    children: [
                      Icon(code == current ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(AppLocale.languageNames[code] ?? code, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              )
              .toList(),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.translate_rounded, size: 14, color: Colors.white),
                const SizedBox(width: 5),
                Text(AppLocale.languageShort[current] ?? "EN", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                const Icon(Icons.arrow_drop_down_rounded, size: 16, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }
}
