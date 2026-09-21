import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class OcrResult {
  final String text;
  final List<String> barcodes;
  
  OcrResult(this.text, this.barcodes);
}

class OcrService {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);

  Future<OcrResult> processImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    
    // Process Text
    final recognizedText = await textRecognizer.processImage(inputImage);
    String fullText = recognizedText.text;
    
    // Process Barcodes
    final barcodesList = await barcodeScanner.processImage(inputImage);
    List<String> foundBarcodes = [];
    for (Barcode barcode in barcodesList) {
      if (barcode.rawValue != null) {
        foundBarcodes.add(barcode.rawValue!);
        // Inject explicitly so the LLM and the Debug View see the true scanner output!
        fullText += "\n\n[SYSTEM_BARCODE_SCANNER_DETECTED: ${barcode.rawValue}]\n";
      }
    }
    
    return OcrResult(fullText, foundBarcodes);
  }

  void dispose() {
    textRecognizer.close();
    barcodeScanner.close();
  }
}
