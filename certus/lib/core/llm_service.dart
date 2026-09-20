import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

abstract class LlmService {
  Future<Map<String, dynamic>?> extractJson(String prompt, String ocrText);
  Future<String> answerQuestion(String prompt, String contextText, String question);
}

class CertusLlmService implements LlmService {
  final bool isOfflineMode;
  
  CertusLlmService({this.isOfflineMode = true});

  @override
  Future<Map<String, dynamic>?> extractJson(String prompt, String ocrText) async {
    if (isOfflineMode) {
      // Offline LOCAL Model via LiteRT-LM (Gemma 4 E2B)
      // Placed in: /sdcard/Android/data/com.example.certus/files/models/gemma-4-E2B-it.litertlm
      // E.g., await liteRtChannel.invokeMethod('generate', {'prompt': "${prompt}\n${ocrText}"});
      await Future.delayed(const Duration(seconds: 1));
      return {
        "product_name": "Sample Product",
        "mrp": 50.0,
        "expiry_date": "2025-12-31"
      };
    } else {
      // Online FALLBACK Model via Gemini API
      try {
        final apiKey = dotenv.env['GEMINI_API_KEY'];
        if (apiKey == null || apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
          throw Exception('Missing Gemini API Key in .env file');
        }
        final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
        final content = [Content.text("${prompt}\n${ocrText}")];
        final response = await model.generateContent(content);
        final text = response.text?.replaceAll('`json', '').replaceAll('`', '') ?? '{}';
        return jsonDecode(text) as Map<String, dynamic>;
      } catch (e) {
        print("API Error: $e");
        return null;
      }
    }
  }

  @override
  Future<String> answerQuestion(String prompt, String contextText, String question) async {
    if (isOfflineMode) {
      await Future.delayed(const Duration(seconds: 1));
      return "This is a local inference answer for: $question";
    } else {
      try {
        final apiKey = dotenv.env['GEMINI_API_KEY'];
        final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey!);
        final content = [Content.text("${prompt}\nContext: $contextText\nQuestion: $question")];
        final response = await model.generateContent(content);
        return response.text ?? "I'm not sure.";
      } catch (e) {
        return "Sorry, I couldn't process the question online.";
      }
    }
  }
}
