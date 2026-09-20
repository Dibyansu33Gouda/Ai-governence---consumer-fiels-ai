import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'ask_screen.dart';
import '../core/pdf_service.dart';
import '../core/ocr_service.dart';
import '../core/llm_service.dart';
import '../core/rule_engine.dart';
import '../core/validators.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final String documentType;
  final String timestamp;
  
  const ResultScreen({super.key, required this.imagePath, required this.documentType, required this.timestamp});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isProcessing = true;
  String _ocrText = "";
  Map<String, dynamic> _extractedData = {};
  List<Finding> _findings = [];
  String _verdict = "Processing...";
  
  @override
  void initState() {
    super.initState();
    _processDocument();
  }

  Future<void> _processDocument() async {
    try {
      // 1. OCR processing
      final ocrService = OcrService();
      final ocrResult = await ocrService.processImage(File(widget.imagePath));
      _ocrText = ocrResult.text;
      
      // 2. LLM Extraction (Live Online via Gemini API)
      final llmService = CertusLlmService(isOfflineMode: false);
      final prompt = "Return ONLY valid JSON. Extract details from this \. If label, include mrp, barcode, expiry_date, fssai_number, is_food (bool), category. If invoice, include supplier_gstin, grand_total, doc_title. Do not use markdown blocks.";
      final data = await llmService.extractJson(prompt, _ocrText);
      
      if (!mounted) return;
      
      _extractedData = data ?? {};
      _extractedData['timestamp'] = widget.timestamp;
      if (ocrResult.barcodes.isNotEmpty) {
         _extractedData['barcode'] = ocrResult.barcodes.first; // populate barcode field for rules
      }

      // 3. Rule Engine Execution
      String rulebookAsset = widget.documentType == 'product' ? 'assets/rulebooks/label_rules.json' : 'assets/rulebooks/gst_rules.json';
      String rulebookString = await rootBundle.loadString(rulebookAsset);
      Map<String, dynamic> book = jsonDecode(rulebookString);

      // Map validators
      final validatorsMap = <String, Validator>{
        'ean13': (doc, node) => isValidEan13(doc[node['field']]?.toString() ?? ''),
        'gs1_india': (doc, node) => isGs1IndiaPrefix(doc[node['field']]?.toString() ?? ''),
        'fssai_shape': (doc, node) => isFssaiShape(doc[node['field']]?.toString() ?? ''),
        'bis_huid': (doc, node) => isBisHuidShape(doc[node['field']]?.toString() ?? ''),
        'gstin_format': (doc, node) => isValidGstin(doc[node['field']]?.toString() ?? ''),
        'gstin_checksum': (doc, node) => isValidGstin(doc[node['field']]?.toString() ?? ''),
        'pan_entity': (doc, node) => panEntityOk(doc[node['field']]?.toString() ?? ''),
      };

      final engine = RuleEngine(validatorsMap);
      
      // Convert documentType to match rulebook applies_to (product->label, bill->invoice)
      String appliesTo = widget.documentType == 'product' ? 'label' : 'invoice';
      
      _findings = engine.run(book, appliesTo, _extractedData);

      // 4. Calculate Final Verdict dynamically
      if (_ocrText.trim().isEmpty) {
        _verdict = "CANNOT_READ";
      } else if (_findings.any((f) => f.severity == Severity.fail)) {
        _verdict = "CHECK_THESE";
      } else if (_findings.any((f) => f.severity == Severity.warn)) {
        _verdict = "MINOR_POINTS";
      } else {
        _verdict = "NO_PROBLEMS";
      }

      setState(() {
        _isProcessing = false;
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _verdict = "ERROR: $e";
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        actions: [
          if (!_isProcessing) IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final pdfService = PdfService();
              final file = await pdfService.generateEvidencePdf(
                docType: widget.documentType,
                verdict: _verdict,
                extractedFields: _extractedData
              );
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to \')));
            },
          )
        ],
      ),
      body: _isProcessing 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C3E50)))
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  color: _verdict == 'NO_PROBLEMS' ? const Color(0xFFE8F8F5) : const Color(0xFFFDECEA),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          _verdict == 'NO_PROBLEMS' ? Icons.check_circle : Icons.warning_amber_rounded, 
                          color: _verdict == 'NO_PROBLEMS' ? const Color(0xFF27AE60) : const Color(0xFFC0392B), 
                          size: 40
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Verdict: \', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _verdict == 'NO_PROBLEMS' ? const Color(0xFF27AE60) : const Color(0xFFC0392B))),
                              const SizedBox(height: 8),
                              Text('Captured: \', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('AI Rule Engine Findings:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Expanded(
                  child: _findings.isEmpty 
                    ? const Center(child: Text("All standard checks passed."))
                    : ListView.builder(
                        itemCount: _findings.length,
                        itemBuilder: (context, index) {
                           final f = _findings[index];
                           return ListTile(
                             leading: Icon(f.severity == Severity.fail ? Icons.cancel : Icons.info, color: f.severity == Severity.fail ? Colors.red : Colors.orange),
                             title: Text(f.messageKey), // Usually would map i18n key here
                             subtitle: Text("Cite: \ | Rule: \"),
                           );
                        }
                      ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AskScreen(contextText: _ocrText)));
                  },
                  icon: const Icon(Icons.mic),
                  label: const Text('Ask a Question'),
                )
              ],
            ),
          ),
    );
  }
}
