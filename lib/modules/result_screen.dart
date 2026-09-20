import 'package:flutter/material.dart';
import 'ask_screen.dart';
import '../core/pdf_service.dart';

class ResultScreen extends StatelessWidget {
  final String imagePath;
  final String documentType;
  final String timestamp;
  
  const ResultScreen({super.key, required this.imagePath, required this.documentType, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final pdfService = PdfService();
              final file = await pdfService.generateEvidencePdf(
                docType: documentType,
                verdict: 'CHECK_THESE',
                extractedFields: {'product_name': 'Sample', 'mrp': '50', 'timestamp': timestamp}
              );
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: const Color(0xFFFDECEA),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B), size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Check these points', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC0392B))),
                          const SizedBox(height: 4),
                          const Text('Rule P-10: Barcode checksum is invalid.'),
                          const SizedBox(height: 8),
                          Text('Captured: $timestamp', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const AskScreen()));
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
