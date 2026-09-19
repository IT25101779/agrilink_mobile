import 'app_locale.dart';

/// Tiny helper for the new screens: pick the English or the Sinhala text
/// for the language the farmer currently has selected.
///
///   Text(tr("Join lot", "එක්වන්න"))
///
/// Screens that use it are wrapped in a ListenableBuilder on
/// AppLocale.instance, so they rebuild the moment the language is toggled.
bool isSinhala() => AppLocale.instance.languageCode == "si";

String tr(String en, String si) => isSinhala() ? si : en;
