import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeechEnabled = false;

  Future<void> init() async {
    // Optimizing microphone initialization
    _isSpeechEnabled = await _speechToText.initialize(
      onError: (e) => print("Speech Error: $e"),
      onStatus: (s) => print("Speech Status: $s"),
    );
    // Use local high-quality voice, disable network for speed
    await _flutterTts.setLanguage("en-IN"); 
    await _flutterTts.setSpeechRate(0.5);
    // OPTIMIZATION: Wait for completion to avoid audio overlap/cutting off
    await _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text) async {
    // Ensures crisp, delay-free playback
    await _flutterTts.speak(text);
  }
  
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  Future<void> startListening(Function(String) onResult) async {
    if (_isSpeechEnabled) {
      // OPTIMIZATION: partialResults = false to avoid UI jitter and processing delays.
      // listenFor limits recording length for faster response.
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 2),
        partialResults: false,
        localeId: "en_IN",
      );
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }
}
