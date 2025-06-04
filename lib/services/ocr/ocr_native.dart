import 'dart:io' show File, Platform;
import 'package:process_run/shell.dart';
import 'dart:convert';

class OCRNative {
  String get _pythonPath {
    if (Platform.isWindows) {
      return 'python';
    } else {
      return 'python3';
    }
  }

  final String _scriptPath = 'ocr.py';

  Future<Map<String, dynamic>> runOcr(String imagePath) async {
    try {
      if (!File(imagePath).existsSync()) {
        throw Exception('Nie można znaleźć wybranego obrazu: $imagePath');
      }

      if (!File(_scriptPath).existsSync()) {
        throw Exception('Nie można znaleźć skryptu OCR: $_scriptPath');
      }

      final shell = Shell();
      final escapedScriptPath =
          _scriptPath.contains(' ') ? '"$_scriptPath"' : _scriptPath;
      final escapedImagePath =
          imagePath.contains(' ') ? '"$imagePath"' : imagePath;

      final command = '$_pythonPath $escapedScriptPath $escapedImagePath';
      print('Uruchamianie: $command');

      final pythonResult = await shell.run(command);

      if (pythonResult.isEmpty) {
        throw Exception('Brak odpowiedzi ze skryptu Python');
      }

      final processResult = pythonResult.first;

      if (processResult.exitCode != 0) {
        final errorMsg = processResult.stderr.toString();
        print('Błąd stderr: $errorMsg');

        if (errorMsg.contains('python') && errorMsg.contains('not found')) {
          throw Exception(
            'Python nie jest zainstalowany lub niedostępny w PATH',
          );
        }

        throw Exception(
          'Błąd skryptu Python (kod: ${processResult.exitCode}): $errorMsg',
        );
      }

      final outputStr = processResult.stdout.toString().trim();
      if (outputStr.isEmpty) {
        throw Exception('Pusty wynik ze skryptu Python');
      }

      print('Wynik skryptu: $outputStr');

      try {
        final output = json.decode(outputStr);
        if (output.containsKey('error')) {
          throw Exception(output['error']);
        }

        final results = output['results'] as List;
        final recognizedText = results
            .map((result) => result['text'] as String)
            .where((text) => text.isNotEmpty)
            .join(' ');

        return {
          'text': recognizedText,
          'confidence': (output['confidence'] as num?)?.toDouble() ?? 0.9,
        };
      } catch (jsonError) {
        throw Exception('Błąd parsowania JSON: $jsonError');
      }
    } catch (e) {
      print('Szczegółowy błąd OCR: $e');
      throw Exception('Błąd OCR: $e');
    }
  }
}
