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
  
  String _recognizedText = "Awaiting audio input...";
  String _answerText = "";
  bool _isListening = false;
bool _isProcessingLLM = false;
  bool _hasMicPermission = false;
  
  String _selectedLanguageCode = 'en';

  final Map<String, Map<String, String>> _languageMap = {
    'en': {'label': 'ENG', 'stt': 'en_IN', 'tts': 'en-IN', 'llm': 'English'},
    'hi': {'label': 'HIN', 'stt': 'hi_IN', 'tts': 'hi-IN', 'llm': 'Hindi'},
    'or': {'label': 'ODI', 'stt': 'or_IN', 'tts': 'or-IN', 'llm': 'Odia'},
    'te': {'label': 'TEL', 'stt': 'te_IN', 'tts': 'te-IN', 'llm': 'Telugu'},
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
    if (!_hasMicPermission || _isProcessingLLM) return;
    
    final currentLang = _languageMap[_selectedLanguageCode]!;
    
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
      
      setState(() { _answerText = "PROCESSING IN ${currentLang['llm']}..."; _isProcessingLLM = true; });
      
      final answer = await _llmService.answerQuestion(
        "Answer briefly using the context. Keep it direct.", 
        widget.contextText, 
        _recognizedText,
        targetLanguage: currentLang['llm']!
      );
      
      if (mounted) {
        setState(() { _answerText = answer; _isProcessingLLM = false; });
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
        appBar: AppBar(title: const Text('VOICE COMMS')),
        body: const Center(
          child: Text("MIC PERMISSION DENIED", style: TextStyle(color: Color(0xFFFF3333), fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('VOICE COMMS'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<String>(
              value: _selectedLanguageCode,
              dropdownColor: const Color(0xFF141414),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFFD600)),
              style: const TextStyle(color: Color(0xFFFFD600), fontWeight: FontWeight.bold, fontFamily: 'monospace'),
              items: _languageMap.keys.map((String code) {
                return DropdownMenuItem<String>(
                  value: code,
                  child: Text(_languageMap[code]!['label']!),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedLanguageCode = newValue;
                    _recognizedText = "SYS_LANG_SWITCHED: ${_languageMap[newValue]!['label']}";
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('> USER_INPUT', style: TextStyle(color: Color(0xFFFFD600), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                      Text(_recognizedText, style: const TextStyle(fontSize: 18, color: Colors.white, height: 1.4)),
                      const Divider(height: 40, color: Color(0xFF2A2A2A)),
                      const Text('> SYS_RESPONSE', style: TextStyle(color: Color(0xFFFFD600), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontFamily: 'monospace')),
                      const SizedBox(height: 8),
                      Text(_answerText, style: const TextStyle(fontSize: 18, color: Colors.white70, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _toggleListening,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isProcessingLLM ? Colors.grey : (_isListening ? const Color(0xFFFF3333) : const Color(0xFFFFD600)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Icon(
                  _isListening ? Icons.stop : Icons.mic, 
                  size: 40, 
                  color: _isListening ? Colors.white : Colors.black
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isListening ? 'RECORDING... [TAP TO STOP]' : '[TAP TO SPEAK]', 
              style: TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.bold, 
                letterSpacing: 2.0, 
                color: _isListening ? const Color(0xFFFF3333) : const Color(0xFFFFD600)
              )
            ),
          ],
        ),
      ),
    );
  }
}

