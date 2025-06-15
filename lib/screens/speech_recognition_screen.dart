import 'package:flutter/material.dart';
import '../services/process_speech_service.dart';

class SpeechRecognitionScreen extends StatefulWidget {
  const SpeechRecognitionScreen({Key? key}) : super(key: key);

  @override
  State<SpeechRecognitionScreen> createState() => _SpeechRecognitionScreenState();
}

class _SpeechRecognitionScreenState extends State<SpeechRecognitionScreen> {
  final ProcessSpeechService _speechService = ProcessSpeechService();
  final TextEditingController _textController = TextEditingController();
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    // Opóźnij inicjalizację do następnej klatki
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeech();
    });
  }

  Future<void> _initializeSpeech() async {
    // Skonfiguruj callback'i
    _speechService.onResult = (text) {
      setState(() {
        // DODAJ tekst zamiast zastępować
        if (_textController.text.isEmpty) {
          _textController.text = text;
        } else {
          _textController.text += ' ' + text;
        }
      });
    };
    
    _speechService.onError = (error) {
      setState(() {
        _errorMessage = error;
      });
      _showErrorSnackBar(error);
    };
    
    _speechService.onListeningStateChanged = (isListening) {
      setState(() {
        _isListening = isListening;
      });
    };

    // Inicjalizuj serwis
    bool initialized = await _speechService.initialize();
    setState(() {
      _isInitialized = initialized;
      if (!initialized) {
        _errorMessage = 'Nie udało się zainicjalizować rozpoznawania mowy';
      }
    });
  }

  void _startListening() async {
    if (!_isInitialized) return;
    
    setState(() {
      _errorMessage = '';
    });
    
    await _speechService.startListening(
      languageCode: 'pl-PL', // POPRAWIONY PARAMETR
      timeout: const Duration(seconds: 8), // POPRAWIONY TIMEOUT
    );
  }

  void _stopListening() async {
    await _speechService.stopListening();
  }

  void _cancelListening() async {
    await _speechService.cancelListening();
    setState(() {
      _textController.clear();
    });
  }

  void _clearText() {
    _speechService.clearText();
    setState(() {
      _textController.clear();
      _errorMessage = '';
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _saveText() {
    if (_textController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tekst został zapisany'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _speechService.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rozpoznawanie mowy'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearText,
            tooltip: 'Wyczyść tekst',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveText,
            tooltip: 'Zapisz tekst',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Status inicjalizacji
            if (!_isInitialized)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Inicjalizowanie rozpoznawania mowy...',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Komunikat o błędzie
            if (_errorMessage.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Status nasłuchiwania
            if (_isListening)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.green),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Nasłuchuję... Mów po polsku! (8s)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    // Animowana ikona mikrofonu
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.graphic_eq,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),

            // Pole tekstowe z rozpoznanym tekstem
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'Rozpoznany tekst pojawi się tutaj...',
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Przyciski sterowania
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Przycisk Start/Stop
                ElevatedButton.icon(
                  onPressed: _isInitialized 
                    ? (_isListening ? _stopListening : _startListening)
                    : null,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic),
                  label: Text(_isListening ? 'ZATRZYMAJ' : 'MÓWIĘ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),

                // Przycisk Anuluj
                ElevatedButton.icon(
                  onPressed: _isInitialized ? _cancelListening : null,
                  icon: const Icon(Icons.cancel),
                  label: const Text('ANULUJ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Tekst informacyjny
            Text(
              _isInitialized 
                ? 'Naciśnij MÓWIĘ i powiedz zdania po polsku (8s)\nKażde nagranie DODAJE się do poprzedniego tekstu'
                : 'Inicjalizowanie...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}