import 'app_locale.dart';

/// Tiny helper for the new screens: pick the English or the Sinhala text
/// for the language the farmer currently has selected.
///
///   Text(tr("Join lot", "එක්වන්න", "குழுவில் சேர்"))
///
/// Screens that use it are wrapped in a ListenableBuilder on
/// AppLocale.instance, so they rebuild the moment the language is toggled.
bool isSinhala() => AppLocale.instance.languageCode == "si";

bool isTamil() => AppLocale.instance.languageCode == "ta";

/// [ta] is optional: a text without a Tamil version simply shows in English
/// for Tamil users instead of showing nothing.
String tr(String en, String si, [String? ta]) {
  switch (AppLocale.instance.languageCode) {
    case "si":
      return si;
    case "ta":
      return ta ?? en;
    default:
      return en;
  }
}
