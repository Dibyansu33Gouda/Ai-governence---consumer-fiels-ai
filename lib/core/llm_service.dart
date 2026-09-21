import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CertusLlmService {
  final bool isOfflineMode;
  late final GenerativeModel _onlineModel;
  
  CertusLlmService({this.isOfflineMode = true}) {
    if (!isOfflineMode) {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) {
        throw Exception("GEMINI_API_KEY not found in .env");
      }
      _onlineModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
      );
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
      final response = await _onlineModel.generateContent([Content.text(prompt)]);
      if (response.text != null) {
        String cleaned = response.text!.trim();
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

    final prompt = '''
Context Document:
$contextText

User Question: $question
Instruction: $instruction. You MUST respond natively and accurately in the following language: $targetLanguage.
If the user asks to translate the document, translate the entire context accurately into $targetLanguage.
    ''';
    
    try {
      final response = await _onlineModel.generateContent([Content.text(prompt)]);
      return response.text ?? "Sorry, I could not understand the question.";
    } catch (e) {
      print("LLM Error: $e");
      return "Error connecting to AI assistant.";
    }
  }
}
