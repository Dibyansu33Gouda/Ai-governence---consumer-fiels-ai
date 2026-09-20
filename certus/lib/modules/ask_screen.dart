import 'package:flutter/material.dart';
import '../core/speech_service.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final SpeechService _speechService = SpeechService();
  String _recognizedText = "Tap the microphone and ask...";
  String _answerText = "";
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechService.init();
  }

  @override
  void dispose() {
    _speechService.stopSpeaking();
    super.dispose();
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
      
      // Mocking the LLM Answer based on speech
      setState(() {
        _answerText = "I found an issue with the barcode checksum according to rule P-10. This could just be a printing error.";
      });
      await _speechService.speak(_answerText);
    } else {
      await _speechService.startListening((text) {
        setState(() {
          _recognizedText = text;
        });
      });
      setState(() => _isListening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask Certus')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('You asked:', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(_recognizedText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const Divider(height: 32),
                    Text('Certus:', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(_answerText, style: const TextStyle(fontSize: 18, color: Color(0xFF2C3E50))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _toggleListening,
              child: CircleAvatar(
                radius: 40,
                backgroundColor: _isListening ? const Color(0xFFC0392B) : const Color(0xFFE67E22),
                child: Icon(_isListening ? Icons.stop : Icons.mic, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(_isListening ? 'Listening...' : 'Tap to speak', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
