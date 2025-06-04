import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'ocr_native.dart';

import 'ocr_web.dart' if (dart.library.io) 'ocr_web_stub.dart';

class OCRService {
  late final _ocrNative = OCRNative();

  Future<String?> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      if (kIsWeb) {
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          return _createBlobUrl(bytes);
        }
      } else {
        if (result.files.single.path != null) {
          return result.files.single.path;
        }
      }
    }
    return null;
  }

  String? _createBlobUrl(List<int> bytes) {
    if (kIsWeb) {
      return OCRWeb.createBlobUrl(bytes);
    }
    return null;
  }

  Future<Map<String, dynamic>> processImage(String imagePath) async {
    if (kIsWeb) {
      final ocrWeb = OCRWeb();
      return await ocrWeb.runOcr(imagePath);
    } else {
      return await _ocrNative.runOcr(imagePath);
    }
  }
}
