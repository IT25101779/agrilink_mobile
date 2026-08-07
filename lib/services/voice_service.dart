import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../localization/app_locale.dart';

/// Wraps speech-to-text (voice input) and text-to-speech (read-aloud)
/// behind one simple API, using whichever language the farmer currently
/// has selected in [AppLocale].
///
/// HONEST LIMITATION: Sinhala speech recognition support varies by platform.
/// Native Android devices with Google's Sinhala voice pack installed work
/// well; browser-based speech (Chrome's Web Speech API, used when running
/// via `flutter run -d chrome`) has inconsistent Sinhala coverage as of
/// this writing. English works reliably everywhere. Text-to-speech (read
/// aloud) has broader Sinhala support than speech recognition since it
/// relies on the device's installed TTS voices rather than a live
/// recognition service.
class VoiceService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static final FlutterTts _tts = FlutterTts();
  static bool _speechInitialized = false;

  static Future<bool> initSpeech() async {
    if (_speechInitialized) return true;
    _speechInitialized = await _speech.initialize(
      onError: (error) => print("Speech recognition error: $error"),
      onStatus: (status) => print("Speech recognition status: $status"),
    );
    return _speechInitialized;
  }

  static bool get isListening => _speech.isListening;

  /// Starts listening and streams partial/final transcripts to [onResult].
  /// Returns false immediately if the device has no speech recognition
  /// available or the farmer denied microphone permission.
  static Future<bool> startListening({
    required void Function(String text) onResult,
    required void Function() onDone,
  }) async {
    final available = await initSpeech();
    if (!available) return false;

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) onDone();
      },
      localeId: AppLocale.instance.speechLocaleId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
    );
    return true;
  }

  static Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Reads [text] aloud in the farmer's currently selected language.
  static Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    final localeId = AppLocale.instance.languageCode == "si" ? "si-LK" : "en-US";
    try {
      await _tts.setLanguage(localeId);
    } catch (_) {
      // Falls back to device default voice if the requested locale
      // isn't installed — better to speak in the wrong accent than
      // not speak at all.
    }
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.0);
    await _tts.stop();
    await _tts.speak(text);
  }

  static Future<void> stopSpeaking() async {
    await _tts.stop();
  }
}
