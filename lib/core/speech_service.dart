import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeechEnabled = false;

  Future<void> init() async {
    _isSpeechEnabled = await _speechToText.initialize(
      onError: (e) => print("Speech Error: $e"),
      onStatus: (s) => print("Speech Status: $s"),
    );
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text, {String languageCode = 'en-IN'}) async {
    // Attempt to set the exact language. 
    // Fallback handling is managed natively by Android if a voice isn't installed.
    await _flutterTts.setLanguage(languageCode);
    await _flutterTts.speak(text);
  }
  
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  Future<void> startListening(Function(String) onResult, {String localeId = 'en_IN'}) async {
    if (_isSpeechEnabled) {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 15), // Increased for longer translations
        pauseFor: const Duration(seconds: 3),
        partialResults: false,
        localeId: localeId, // dynamically inject the language to listen for
      );
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }
}
