import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/speech_service.dart';
import '../core/llm_service.dart';

class AskScreen extends StatefulWidget {
  final String contextText;
  
  const AskScreen({super.key, required this.contextText});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final SpeechService _speechService = SpeechService();
  final CertusLlmService _llmService = CertusLlmService(isOfflineMode: false);
  
  String _recognizedText = "Tap the microphone and ask...";
  String _answerText = "";
  bool _isListening = false;
  bool _hasMicPermission = false;
  
  // Multi-language state
  String _selectedLanguageCode = 'en';

  final Map<String, Map<String, String>> _languageMap = {
    'en': {'label': 'English', 'stt': 'en_IN', 'tts': 'en-IN', 'llm': 'English'},
    'hi': {'label': 'हिंदी (Hindi)', 'stt': 'hi_IN', 'tts': 'hi-IN', 'llm': 'Hindi'},
    'or': {'label': 'ଓଡ଼ିଆ (Odia)', 'stt': 'or_IN', 'tts': 'or-IN', 'llm': 'Odia'},
    'te': {'label': 'తెలుగు (Telugu)', 'stt': 'te_IN', 'tts': 'te-IN', 'llm': 'Telugu'},
  };

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInit();
  }
  
  Future<void> _checkPermissionsAndInit() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      if (mounted) {
        setState(() => _hasMicPermission = true);
      }
      await _speechService.init();
    }
  }

  @override
  void dispose() {
    _speechService.stopSpeaking();
    super.dispose();
  }

  void _toggleListening() async {
    if (!_hasMicPermission) return;
    
    final currentLang = _languageMap[_selectedLanguageCode]!;
    
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
      
      setState(() => _answerText = "Thinking in \...");
      
      // Query LLM with explicit translation/language instructions
      final answer = await _llmService.answerQuestion(
        "Answer briefly using the context.", 
        widget.contextText, 
        _recognizedText,
        targetLanguage: currentLang['llm']!
      );
      
      if (mounted) {
        setState(() => _answerText = answer);
        await _speechService.speak(_answerText, languageCode: currentLang['tts']!);
      }
    } else {
      await _speechService.startListening((text) {
        if (mounted) {
          setState(() {
            _recognizedText = text;
          });
        }
      }, localeId: currentLang['stt']!);
      
      setState(() => _isListening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasMicPermission) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ask Certus')),
        body: const Center(
          child: Text("Microphone permission required to use Voice Q&A", style: TextStyle(fontSize: 16)),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Certus'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedLanguageCode,
              dropdownColor: Colors.white,
              underline: const SizedBox(),
              icon: const Icon(Icons.language, color: Colors.black87),
              items: _languageMap.keys.map((String code) {
                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(_languageMap[code]!['label']!, style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguageCode = newValue;
                    _recognizedText = "Language switched to \";
                  });
                }
              },
            ),
          )
        ],
      ),
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
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('You asked:', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(_recognizedText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      const Divider(height: 32),
                      Text('Certus:', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(_answerText, style: const TextStyle(fontSize: 18, color: const Color(0xFF2C3E50))),
                    ],
                  ),
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
            Text(_isListening ? 'Listening (Tap to stop)...' : 'Tap to speak', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
