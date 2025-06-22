import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> saveZipFile(Uint8List bytes, String filename) async {
  final tempDir = await getTemporaryDirectory();
  final zipPath = '${tempDir.path}/$filename';
  final file = File(zipPath);
  await file.writeAsBytes(bytes);
  print('ZIP zapisany do: $zipPath');
}
