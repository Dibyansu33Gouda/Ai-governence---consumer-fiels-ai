import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'masking.dart';

class PdfService {
  Future<File> generateEvidencePdf({
    required String docType,
    required String verdict,
    required Map<String, dynamic> extractedFields,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, child: pw.Text('Certus Evidence Report')),
              pw.Text('Date: ${DateTime.now().toIso8601String()}'),
              pw.SizedBox(height: 20),
              pw.Text('Document Type: $docType', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Verdict: $verdict', style: const pw.TextStyle(color: PdfColors.red, fontSize: 18)),
              pw.SizedBox(height: 20),
              pw.Text('Extracted Data (PII Masked):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ...extractedFields.entries.map((e) {
                return pw.Text('${e.key}: ${maskAll(e.value.toString())}');
              }),
              pw.Spacer(),
              pw.Text('Automated check. Not legal or tax advice.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    final output = await getApplicationDocumentsDirectory();
    final file = File("${output.path}/evidence_report.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
