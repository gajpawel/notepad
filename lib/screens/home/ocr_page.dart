import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:process_run/process_run.dart';
import 'package:file_picker/file_picker.dart';

class OCRPage extends StatefulWidget {
  const OCRPage({super.key});

  @override
  State<OCRPage> createState() => _OCRPageState();
}

class _OCRPageState extends State<OCRPage> {
  bool _isProcessing = false;
  String _recognizedText = '';
  List<Map<String, dynamic>> _ocrResults = [];
  String? _selectedImagePath;

  final String _pythonPath = 'python';
  final String _scriptPath = 'ocr.py';

  @override
  void dispose() {
    _recognizedText = '';
    _ocrResults.clear();
    super.dispose();
  }

  Future<void> _pickImageAndRun() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      String imagePath = result.files.single.path!;
      setState(() {
        _selectedImagePath = imagePath;
      });
      await _runOcrProcess(imagePath);
    }
  }

  Future<void> _runOcrProcess(String imagePath) async {
    setState(() {
      _isProcessing = true;
      _recognizedText = '';
      _ocrResults.clear();
    });

    try {
      if (!File(imagePath).existsSync()) {
        throw Exception('Nie można znaleźć wybranego obrazu');
      }

      final shell = Shell();

      final escapedScriptPath =
          _scriptPath.contains(' ') ? '"$_scriptPath"' : _scriptPath;
      final escapedImagePath =
          imagePath.contains(' ') ? '"$imagePath"' : imagePath;

      print('Uruchamianie: $_pythonPath $escapedScriptPath $escapedImagePath');

      final pythonResult = await shell.run(
        '$_pythonPath $escapedScriptPath $escapedImagePath',
      );

      if (pythonResult.isEmpty) {
        throw Exception('Brak odpowiedzi ze skryptu Python');
      }

      final processResult = pythonResult.first;

      if (processResult.exitCode != 0) {
        final errorMsg = processResult.stderr.toString();
        print('Błąd stderr: $errorMsg');
        throw Exception(
          'Błąd skryptu Python (kod: ${processResult.exitCode}): $errorMsg',
        );
      }

      final outputStr = processResult.stdout.toString().trim();
      if (outputStr.isEmpty) {
        throw Exception('Pusty wynik ze skryptu Python');
      }

      print('Wynik skryptu: $outputStr');

      final output = json.decode(outputStr);
      if (output.containsKey('error')) {
        throw Exception(output['error']);
      }

      final results = output['results'] as List;
      setState(() {
        _ocrResults = results.cast<Map<String, dynamic>>();
        _recognizedText = results
            .map((result) => result['text'] as String)
            .where((text) => text.isNotEmpty)
            .join(' ');
        _isProcessing = false;
      });

      if (_recognizedText.isNotEmpty) {
        _showMessage('Rozpoznano tekst z obrazu!');
      } else {
        _showMessage('Nie rozpoznano tekstu z obrazu');
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      print('Błąd OCR: $e');
      _showMessage('Błąd podczas przetwarzania obrazu: $e');
    }
  }

  void _clearResults() {
    setState(() {
      _selectedImagePath = null;
      _recognizedText = '';
      _ocrResults.clear();
    });
  }

  Future<void> _copyTextToClipboard() async {
    if (_recognizedText.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _recognizedText));
    _showMessage('Tekst skopiowany do schowka');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildImagePreview() {
    if (_selectedImagePath == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(_selectedImagePath!),
          height: 200,
          width: double.infinity,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (_ocrResults.isEmpty && !_isProcessing) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text(
                'Rozpoznany tekst',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isProcessing)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Przetwarzanie obrazu...'),
                ],
              ),
            )
          else if (_recognizedText.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SelectableText(
                _recognizedText,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),

            ExpansionTile(
              title: const Text('Szczegóły rozpoznawania'),
              children:
                  _ocrResults.map((result) {
                    final confidence = ((result['confidence'] as double) * 100)
                        .toStringAsFixed(1);
                    return ListTile(
                      leading: Icon(
                        Icons.text_snippet,
                        color:
                            result['confidence'] > 0.7
                                ? Colors.green
                                : Colors.orange,
                      ),
                      title: Text(result['text']),
                      subtitle: Text('Pewność: $confidence%'),
                    );
                  }).toList(),
            ),
          ] else
            const Text(
              'Nie rozpoznano żadnego tekstu w obrazie',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozpoznawanie tekstu OCR'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_recognizedText.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearResults,
              tooltip: 'Wyczyść wyniki',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Jak używać',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Kliknij "Wybierz obraz i uruchom OCR"\n'
                    '2. Wybierz obraz z dysku\n'
                    '3. Poczekaj na przetworzenie obrazu\n'
                    '4. Rozpoznany tekst pojawi się poniżej',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickImageAndRun,
                icon:
                    _isProcessing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Icon(Icons.image_search, size: 24),
                label: Text(
                  _isProcessing
                      ? 'Przetwarzanie...'
                      : 'Wybierz obraz i uruchom OCR',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),

            _buildImagePreview(),

            _buildResultsSection(),

            if (_recognizedText.isNotEmpty) ...[
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton.icon(
                  onPressed: _copyTextToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Kopiuj tekst'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
