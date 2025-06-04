import 'package:js/js.dart';

@JS('Tesseract.recognize')
external dynamic recognize(dynamic image, String lang, [dynamic options]);

@JS()
@anonymous
class TesseractResult {
  external dynamic get data;
}

@JS()
@anonymous
class TesseractData {
  external String get text;
  external double get confidence;
}
