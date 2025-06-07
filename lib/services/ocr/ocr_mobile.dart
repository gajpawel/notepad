import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class OCRMobile {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  ); // ZMIANA TUTAJ

  Future<Map<String, dynamic>> runOcr(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));

      final recognizedText = await _textRecognizer.processImage(inputImage);

      String text = recognizedText.text;

      double confidence = 1.0;

      return {'text': text, 'confidence': confidence};
    } catch (e) {
      print('Błąd OCR (ML Kit na urządzeniach mobilnych): $e');

      throw Exception('Błąd OCR (ML Kit na urządzeniach mobilnych): $e');
    } finally {
      _textRecognizer.close();
    }
  }
}
