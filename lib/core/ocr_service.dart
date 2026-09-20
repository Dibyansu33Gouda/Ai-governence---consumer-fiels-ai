import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class OcrResult {
  final String text;
  final List<String> barcodes;
  
  OcrResult(this.text, this.barcodes);
}

class OcrService {
  // Using Devanagari script for EN + HI support
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.devanagiri);
  final barcodeScanner = BarcodeScanner();

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
      }
    }
    
    return OcrResult(fullText, foundBarcodes);
  }

  void dispose() {
    textRecognizer.close();
    barcodeScanner.close();
  }
}
