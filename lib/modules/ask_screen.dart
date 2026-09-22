import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/speech_service.dart';
import '../core/llm_service.dart';

class AskScreen extends StatefulWidget {
  final String contextText;
  final String? initialQuestion;
  
  const AskScreen({super.key, required this.contextText, this.initialQuestion});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final SpeechService _speechService = SpeechService();
  final CertusLlmService _llmService = CertusLlmService(isOfflineMode: false);
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _recognizedText = "Tap mic or type a question below...";
  String _answerText = "";
  bool _isListening = false;
  bool _isProcessingLLM = false;
  bool _hasMicPermission = false;
  
  String _selectedLanguageCode = 'en';

  final Map<String, Map<String, String>> _languageMap = {
    'en': {'label': 'ENG', 'stt': 'en_IN', 'tts': 'en-IN', 'llm': 'English'},
    'hi': {'label': 'HIN - हिंदी', 'stt': 'hi_IN', 'tts': 'hi-IN', 'llm': 'Hindi'},
    'or': {'label': 'ODI - ଓଡ଼ିଆ', 'stt': 'or_IN', 'tts': 'or-IN', 'llm': 'Odia'},
    'te': {'label': 'TEL - తెలుగు', 'stt': 'te_IN', 'tts': 'te-IN', 'llm': 'Telugu'},
    'bn': {'label': 'BEN - বাংলা', 'stt': 'bn_IN', 'tts': 'bn-IN', 'llm': 'Bengali'},
    'ta': {'label': 'TAM - தமிழ்', 'stt': 'ta_IN', 'tts': 'ta-IN', 'llm': 'Tamil'},
    'mr': {'label': 'MAR - मराठी', 'stt': 'mr_IN', 'tts': 'mr-IN', 'llm': 'Marathi'},
    'gu': {'label': 'GUJ - ગુજરાતી', 'stt': 'gu_IN', 'tts': 'gu-IN', 'llm': 'Gujarati'},
    'kn': {'label': 'KAN - ಕನ್ನಡ', 'stt': 'kn_IN', 'tts': 'kn-IN', 'llm': 'Kannada'},
  };

  final List<String> _suggestedPrompts = [
    "How do I fill this form field-by-field?",
    "What documents are required to attach?",
    "What common mistakes should I avoid?",
    "Where is the official website to submit?",
    "Is this document valid and verified under law?"
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndInit();
    if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitQuestion(widget.initialQuestion!);
      });
    }
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
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || _isProcessingLLM) return;

    final currentLang = _languageMap[_selectedLanguageCode]!;
    _textController.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _recognizedText = trimmed;
      _answerText = "PROCESSING IN ${currentLang['llm']}...";
      _isProcessingLLM = true;
    });

    final answer = await _llmService.answerQuestion(
      "You are an expert citizen assistant, consumer auditor, and government form specialist. Answer clearly, professionally, and step-by-step using the context provided.", 
      widget.contextText.isNotEmpty ? widget.contextText : "General Indian Consumer Protection and KYC Guidance.", 
      trimmed,
      targetLanguage: currentLang['llm']!
    );

    if (mounted) {
      setState(() {
        _answerText = answer;
        _isProcessingLLM = false;
      });
      await _speechService.speak(_answerText, languageCode: currentLang['tts']!);
    }
  }

  void _toggleListening() async {
    if (!_hasMicPermission) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return;
      setState(() => _hasMicPermission = true);
      await _speechService.init();
    }
    if (_isProcessingLLM) return;
    
    final currentLang = _languageMap[_selectedLanguageCode]!;
    
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
      if (_recognizedText.isNotEmpty && !_recognizedText.startsWith("Listening")) {
        _submitQuestion(_recognizedText);
      }
    } else {
      setState(() {
        _isListening = true;
        _recognizedText = "Listening (${currentLang['label']})... Speak clearly.";
      });
      
      await _speechService.startListening((text) {
        if (mounted) {
          setState(() {
            _recognizedText = text;
          });
        }
      }, localeId: currentLang['stt']!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = _languageMap[_selectedLanguageCode]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI ASSISTANT & VOICE'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: DropdownButton<String>(
              value: _selectedLanguageCode,
              dropdownColor: const Color(0xFF141414),
              underline: const SizedBox(),
              icon: const Icon(Icons.language, color: Color(0xFFFFD600), size: 18),
              style: const TextStyle(color: Color(0xFFFFD600), fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
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
                  });
                }
              },
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick suggested questions chips
            Container(
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestedPrompts.length,
                itemBuilder: (context, index) {
                  final prompt = _suggestedPrompts[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      backgroundColor: const Color(0xFF141414),
                      side: const BorderSide(color: Color(0xFF333333)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      label: Text(prompt, style: const TextStyle(color: Color(0xFFFFD600), fontSize: 11, fontWeight: FontWeight.w600)),
                      onPressed: () => _submitQuestion(prompt),
                    ),
                  );
                },
              ),
            ),

            // Main chat viewport
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  border: Border.all(color: const Color(0xFF222222), width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Color(0xFFFFD600), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '> QUESTION (${currentLang['label']})', 
                            style: const TextStyle(color: Color(0xFFFFD600), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontFamily: 'monospace')
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _recognizedText, 
                        style: const TextStyle(fontSize: 16, color: Colors.white, height: 1.4, fontWeight: FontWeight.w500)
                      ),
                      
                      const Divider(height: 32, color: Color(0xFF222222)),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.smart_toy, color: Color(0xFF00FF66), size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '> AI RESPONSE (${currentLang['llm']?.toUpperCase() ?? ''})', 
                                style: const TextStyle(color: Color(0xFF00FF66), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, fontFamily: 'monospace')
                              ),
                            ],
                          ),
                          if (_answerText.isNotEmpty && !_isProcessingLLM)
                            IconButton(
                              icon: const Icon(Icons.volume_up, color: Color(0xFFFFD600), size: 18),
                              tooltip: "Listen again",
                              onPressed: () => _speechService.speak(_answerText, languageCode: currentLang['tts']!),
                            )
                        ],
                      ),
                      const SizedBox(height: 8),
                      _isProcessingLLM
                          ? const Row(
                              children: [
                                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD600))),
                                SizedBox(width: 12),
                                Text("Analyzing form rules & statutory guides...", style: TextStyle(color: Color(0xFFFFD600), fontSize: 13, fontFamily: 'monospace'))
                              ],
                            )
                          : Text(
                              _answerText.isEmpty ? "Tap the microphone to speak or use the keyboard below to ask any question about this document or form." : _answerText, 
                              style: TextStyle(fontSize: 15, color: _answerText.isEmpty ? Colors.white38 : Colors.white, height: 1.45)
                            ),
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 12),

            // Bottom Control Bar: Dual Input (Keyboard & Voice)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Text Input Field (Works with any keyboard: Gboard, Samsung, regional language scripts)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF141414),
                        border: Border.all(color: const Color(0xFF333333)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: TextField(
                        controller: _textController,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Type in any language (English, Hindi, etc.)...",
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Color(0xFFFFD600), size: 20),
                            onPressed: () => _submitQuestion(_textController.text),
                          ),
                        ),
                        onSubmitted: _submitQuestion,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 10),

                  // Mic Button (Tap to talk)
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _isProcessingLLM 
                            ? Colors.grey 
                            : (_isListening ? const Color(0xFFFF3333) : const Color(0xFFFFD600)),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? const Color(0xFFFF3333) : const Color(0xFFFFD600)).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2)
                          )
                        ]
                      ),
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic, 
                        size: 26, 
                        color: _isListening ? Colors.white : Colors.black
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
