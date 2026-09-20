import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeechEnabled = false;

  Future<void> init() async {
    _isSpeechEnabled = await _speechToText.initialize();
    await _flutterTts.setLanguage("en-IN"); // or hi-IN based on settings
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }
  
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  Future<void> startListening(Function(String) onResult) async {
    if (_isSpeechEnabled) {
      await _speechToText.listen(onResult: (result) {
        onResult(result.recognizedWords);
      });
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }
}
