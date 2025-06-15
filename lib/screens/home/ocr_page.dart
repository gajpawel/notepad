import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show File;
import 'package:Noteable/services/ocr/ocr_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../speech_recognition_screen.dart';

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

  final OCRService _ocrService = OCRService();

  @override
  void dispose() {
    _recognizedText = '';
    _ocrResults.clear();
    super.dispose();
  }

  Future<void> _pickImageAndRun() async {
    final imagePath = await _ocrService.pickImage();
    if (imagePath != null) {
      setState(() {
        _selectedImagePath = imagePath;
        _isProcessing = true;
        _recognizedText = '';
        _ocrResults.clear();
      });

      try {
        final result = await _ocrService.processImage(imagePath);
        setState(() {
          _recognizedText = result['text'] as String;
          _ocrResults = [result];
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
        _showMessage('Błąd podczas przetwarzania obrazu: $e');
      }
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

  // NOWA FUNKCJA - przejście do Speech Recognition
  void _goToSpeechRecognition() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SpeechRecognitionScreen(),
      ),
    );
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
        child:
            kIsWeb
                ? Image.network(
                  _selectedImagePath!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.contain,
                )
                : Image.file(
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
        title: const Text('Rozpoznawanie tekstu'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          // NOWY PRZYCISK - Speech Recognition w AppBar
          IconButton(
            icon: const Icon(Icons.mic),
            onPressed: _goToSpeechRecognition,
            tooltip: 'Rozpoznawanie mowy',
          ),
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
                    '📷 OCR - Rozpoznawanie tekstu z obrazu:\n'
                    '1. Kliknij "Wybierz obraz i uruchom OCR"\n'
                    '2. Wybierz obraz z dysku\n'
                    '3. Poczekaj na przetworzenie obrazu\n\n'
                    '🎤 Speech - Rozpoznawanie mowy:\n'
                    '• Kliknij ikonę mikrofonu w prawym górnym rogu',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // NOWA SEKCJA - Wybór metody rozpoznawania
            Row(
              children: [
                Expanded(
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
                          : 'OCR z obrazu',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _goToSpeechRecognition,
                    icon: const Icon(Icons.mic, size: 24),
                    label: const Text(
                      'Rozpoznaj mowę',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
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