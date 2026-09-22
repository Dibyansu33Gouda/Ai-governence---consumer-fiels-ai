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
Output purely a valid JSON object without markdown formatting, preamble, or commentary. Do not wrap in ```json.
Document Text:
$documentText
    ''';
    
    try {
      final responseText = await _generate(prompt);
      if (responseText != null) {
        String cleaned = responseText.trim();
        if (cleaned.startsWith("```json")) cleaned = cleaned.substring(7);
        if (cleaned.startsWith("```")) cleaned = cleaned.substring(3);
        if (cleaned.endsWith("```")) cleaned = cleaned.substring(0, cleaned.length - 3);
        
        // Find first { and last }
        int start = cleaned.indexOf('{');
        int end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          cleaned = cleaned.substring(start, end + 1);
        }
        return jsonDecode(cleaned.trim());
      }
    } catch (e) {
      print("LLM extractJson Error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> identifyAndDescribeProduct({
    required String scannedCode,
    required String ocrText,
    String? resolvedUrl,
  }) async {
    if (isOfflineMode || _activeEngine == "NONE") return null;

    final prompt = '''
You are an expert consumer product verifier and auditor.
Analyze the following packaging scan and scanned barcode / QR code to identify the exact product, brand, authenticity, and legal details.

Scanned Code: $scannedCode
Resolved Web Link: ${resolvedUrl ?? 'None'}
Packaging Text Detected (OCR):
$ocrText

Return ONLY a pure JSON object (no markdown, no backticks, no preamble) with these exact keys:
{
  "product_name": "Full official product name including flavor/type (e.g. Amul Real Milk Vanilla Ice Cream)",
  "brand": "Manufacturer or Brand Name (e.g. Amul / GCMMF)",
  "category": "Specific category (e.g. Dairy & Ice Cream, Cosmetics, FMCG, Beverage)",
  "description": "Comprehensive, highly detailed 2-3 sentence product description explaining what the product is, key quality attributes, manufacturer authenticity, and purpose.",
  "official_url": "Real official brand website (e.g. https://amul.com)",
  "mrp": "Extracted MRP with currency if visible in OCR or packaging text, else null",
  "expiry_date": "Extracted expiry or best before if visible in OCR, else null",
  "fssai_number": "Extracted 14-digit FSSAI number if food/beverage and visible in OCR, else null",
  "is_authentic_brand": true
}
''';

    try {
      final responseText = await _generate(prompt);
      if (responseText != null) {
        String cleaned = responseText.trim();
        if (cleaned.startsWith("```json")) cleaned = cleaned.substring(7);
        if (cleaned.startsWith("```")) cleaned = cleaned.substring(3);
        if (cleaned.endsWith("```")) cleaned = cleaned.substring(0, cleaned.length - 3);
        int start = cleaned.indexOf('{');
        int end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1 && end > start) {
          cleaned = cleaned.substring(start, end + 1);
        }
        return jsonDecode(cleaned.trim());
      }
    } catch (e) {
      print("LLM identifyAndDescribeProduct Error: $e");
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
      final response = await _geminiModel!.generateContent([Content.text(prompt)]).timeout(const Duration(seconds: 20));
      return response.text;
    } else if (_activeEngine == "GROQ") {
      // Try qwen/qwen3.8-27b first, fallback to openai/gpt-oss-20b
      List<String> modelsToTry = ['qwen/qwen3.8-27b', 'openai/gpt-oss-20b'];
      
      for (String modelName in modelsToTry) {
        try {
          final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
          final request = await HttpClient().postUrl(url).timeout(const Duration(seconds: 15));
          request.headers.set('Authorization', 'Bearer $_groqApiKey');
          request.headers.set('Content-Type', 'application/json');
          request.write(jsonEncode({
            'model': modelName,
            'messages': [
              {'role': 'user', 'content': prompt}
            ],
            'temperature': 0.2
          }));
          final response = await request.close().timeout(const Duration(seconds: 15));
          final responseBody = await response.transform(utf8.decoder).join();
          final json = jsonDecode(responseBody);
          if (response.statusCode == 200 && json['choices'] != null && (json['choices'] as List).isNotEmpty) {
            return json['choices'][0]['message']['content'];
          }
        } catch (e) {
          print("Groq model $modelName failed: $e. Trying fallback...");
        }
      }
      throw Exception("All Groq models failed.");
    }
    return null;
  }
}
