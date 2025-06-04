import 'dart:html' as html;
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import '/utils/tesseract_interop.dart';

class OCRWeb {
  static String createBlobUrl(List<int> bytes) {
    final blob = html.Blob([bytes]);
    return html.Url.createObjectUrlFromBlob(blob);
  }

  Future<Map<String, dynamic>> runOcr(String imageUrl) async {
    try {
      final result = await promiseToFuture(recognize(imageUrl, 'eng+pol'));

      if (result == null || result.data == null) {
        throw Exception(
          'Tesseract.js zwróciło null - nie udało się rozpoznać tekstu',
        );
      }

      final data = result.data as TesseractData;
      final text = data.text ?? '';
      final confidence = data.confidence ?? 0.0;

      return {'text': text, 'confidence': confidence / 100};
    } catch (e) {
      throw Exception('Błąd OCR (web): $e');
    } finally {
      html.Url.revokeObjectUrl(imageUrl);
    }
  }
}
