import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show Platform;

import 'ocr_web.dart' if (dart.library.io) 'ocr_web_stub.dart';
import 'ocr_native.dart';
import 'ocr_mobile.dart';

class OCRService {
  OCRNative? _ocrNative;
  OCRMobile? _ocrMobile;

  Future<String?> pickImage() async {
    if (kIsWeb) {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
        final bytes = result.files.single.bytes;
        if (bytes != null) {
          return _createBlobUrl(bytes);
        }
      }
    } else if (Platform.isAndroid || Platform.isIOS) {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        return image.path;
      }
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null) {
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
    } else if (Platform.isAndroid || Platform.isIOS) {
      _ocrMobile ??= OCRMobile();
      return await _ocrMobile!.runOcr(imagePath);
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      _ocrNative ??= OCRNative();
      return await _ocrNative!.runOcr(imagePath);
    } else {
      throw UnsupportedError('OCR nie jest obsługiwane na tej platformie.');
    }
  }
}
