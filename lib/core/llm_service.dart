import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CertusLlmService {
  final bool isOfflineMode;
  GenerativeModel? _geminiModel;
  String? _groqApiKey;
  String _activeEngine = "NONE";
  String? _initError;
  
  CertusLlmService({this.isOfflineMode = true}) {
    if (!isOfflineMode) {
      try {
        final geminiKey = dotenv.env['GEMINI_API_KEY'];
        final groqKey = dotenv.env['GROQ_API_KEY'];
        
        if (groqKey != null && groqKey.isNotEmpty && groqKey != "YOUR_KEY_HERE") {
          _groqApiKey = groqKey;
          _activeEngine = "GROQ";
        } else if (geminiKey != null && geminiKey.isNotEmpty && geminiKey != "YOUR_KEY_HERE") {
          _geminiModel = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: geminiKey,
          );
          _activeEngine = "GEMINI";
        } else {
          _initError = "No valid API key found in .env (Need GEMINI_API_KEY or GROQ_API_KEY)";
        }
      } catch (e) {
        _initError = e.toString();
      }
    }
  }

  Future<Map<String, dynamic>?> extractJson(String instruction, String documentText) async {
    if (isOfflineMode) {
      await Future.delayed(const Duration(seconds: 1));
      return {"error": "Offline mode strictly requires C++ LiteRT integration."};
    }
    
    final prompt = '''
Instruction: $instruction
Output purely a JSON object without markdown formatting. Do not wrap in `json.
Document Text:
$documentText
    ''';
    
    try {
      final responseText = await _generate(prompt);
      if (responseText != null) {
        String cleaned = responseText.trim();
        if (cleaned.startsWith("`json")) cleaned = cleaned.substring(7);
        if (cleaned.startsWith("`")) cleaned = cleaned.substring(3);
        if (cleaned.endsWith("`")) cleaned = cleaned.substring(0, cleaned.length - 3);
        return jsonDecode(cleaned.trim());
      }
    } catch (e) {
      print("LLM Error: $e");
    }
    return null;
  }
  
  Future<String> answerQuestion(String instruction, String contextText, String question, {String targetLanguage = 'English'}) async {
    if (isOfflineMode) {
      await Future.delayed(const Duration(seconds: 1));
      return "Offline chat mode strictly requires C++ LiteRT integration.";
    }
    if (_activeEngine == "NONE") {
      return "SYS_INIT_ERR: ${_initError}";
    }

    final prompt = '''
Context Document:
$contextText

User Question: $question
Instruction: $instruction. You MUST respond natively and accurately in the following language: $targetLanguage.
If the user asks to translate the document, translate the entire context accurately into $targetLanguage.
    ''';
    
    try {
      final text = await _generate(prompt);
      return text ?? "Sorry, I could not understand the question.";
    } catch (e) {
      print("LLM Error: $e");
      return "SYS_ERR [$_activeEngine]: $e";
    }
  }
  
  Future<String?> _generate(String prompt) async {
    if (_activeEngine == "GEMINI") {
      // No built-in timeout setting in current generative_ai dart package version? 
      // We can wrap it in Future.any or timeout()
      final response = await _geminiModel!.generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 20));
      return response.text;
    } else if (_activeEngine == "GROQ") {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final request = await HttpClient().postUrl(url).timeout(const Duration(seconds: 20));
      request.headers.set('Authorization', 'Bearer $_groqApiKey');
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode({
        'model': 'llama3-8b-8192',
        'messages': [
          {'role': 'user', 'content': prompt}
        ]
      }));
      final response = await request.close().timeout(const Duration(seconds: 20));
      final responseBody = await response.transform(utf8.decoder).join();
      final json = jsonDecode(responseBody);
      if (response.statusCode != 200) {
        throw Exception(json['error']?['message'] ?? 'Groq API Error');
      }
      return json['choices'][0]['message']['content'];
    }
    return null;
  }
}
