import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/process_speech_service.dart';
import '../services/chrome_speech_service.dart';

class SpeechRecognitionScreen extends StatefulWidget {
  const SpeechRecognitionScreen({Key? key}) : super(key: key);

  @override
  State<SpeechRecognitionScreen> createState() => _SpeechRecognitionScreenState();
}

class _SpeechRecognitionScreenState extends State<SpeechRecognitionScreen> {
  final ProcessSpeechService _desktopSpeechService = ProcessSpeechService();
  final ChromeSpeechService _chromeSpeechService = ChromeSpeechService();
  final TextEditingController _textController = TextEditingController();
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _errorMessage = '';
  bool _isWebPlatform = kIsWeb;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSpeech();
    });
  }

  Future<void> _initializeSpeech() async {
    if (_isWebPlatform) {
      // CHROME - prawdziwe Web Speech API (jak Google API w Python)
      _chromeSpeechService.onResult = (text) {
        setState(() {
          if (_textController.text.isEmpty) {
            _textController.text = text;
          } else {
            _textController.text += ' ' + text;
          }
        });
        _showSuccessSnackBar('✅ Rozpoznano: ${text.length > 20 ? text.substring(0, 20) + "..." : text}');
      };
      
      _chromeSpeechService.onError = (error) {
        setState(() {
          _errorMessage = error;
        });
        _showErrorSnackBar(error);
      };
      
      _chromeSpeechService.onListeningStateChanged = (isListening) {
        setState(() {
          _isListening = isListening;
        });
      };

      bool initialized = await _chromeSpeechService.initialize();
      setState(() {
        _isInitialized = initialized;
        if (!initialized) {
          _errorMessage = 'Chrome Web Speech API nie jest dostępny';
        }
      });
      
      if (initialized) {
        _showSuccessSnackBar('🎤 Chrome Speech API gotowy - jak Google API w Python!');
      }
    } else {
      // DESKTOP - Python speech_recognizer.py z Google Speech Recognition
      _desktopSpeechService.onResult = (text) {
        setState(() {
          if (_textController.text.isEmpty) {
            _textController.text = text;
          } else {
            _textController.text += ' ' + text;
          }
        });
        _showSuccessSnackBar('✅ Python rozpoznał: ${text.length > 20 ? text.substring(0, 20) + "..." : text}');
      };
      
      _desktopSpeechService.onError = (error) {
        setState(() {
          _errorMessage = error;
        });
        _showErrorSnackBar(error);
      };
      
      _desktopSpeechService.onListeningStateChanged = (isListening) {
        setState(() {
          _isListening = isListening;
        });
      };

      bool initialized = await _desktopSpeechService.initialize();
      setState(() {
        _isInitialized = initialized;
        if (!initialized) {
          _errorMessage = 'Python Speech Recognition nie jest dostępny';
        }
      });
      
      if (initialized) {
        _showSuccessSnackBar('🐍 Python speech_recognizer.py gotowy!');
      }
    }
  }

  void _startListening() async {
    if (!_isInitialized) return;
    
    setState(() {
      _errorMessage = '';
    });
    
    if (_isWebPlatform) {
      // CHROME - używa Web Speech API (Google w tle)
      await _chromeSpeechService.startListening(
        languageCode: 'pl-PL', // Polski jak w speech_recognizer.py
        timeout: const Duration(seconds: 30), // Długi timeout dla Chrome
      );
    } else {
      // DESKTOP - używa speech_recognizer.py
      await _desktopSpeechService.startListening(
        languageCode: 'pl-PL',
        timeout: const Duration(seconds: 8),
      );
    }
  }

  void _stopListening() async {
    if (_isWebPlatform) {
      await _chromeSpeechService.stopListening();
    } else {
      await _desktopSpeechService.stopListening();
    }
  }

  void _cancelListening() async {
    if (_isWebPlatform) {
      await _chromeSpeechService.cancelListening();
    } else {
      await _desktopSpeechService.cancelListening();
    }
    setState(() {
      _textController.clear();
    });
  }

  void _clearText() {
    if (_isWebPlatform) {
      _chromeSpeechService.clearText();
    } else {
      _desktopSpeechService.clearText();
    }
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
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _saveTextAndReturn() {
    if (_textController.text.isNotEmpty) {
      Navigator.pop(context, _textController.text);
    } else {
      Navigator.pop(context);
    }
  }

  void _showInfoHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isWebPlatform ? '🌐 Chrome Speech API' : '🐍 Python Speech Recognition'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isWebPlatform ? 'Chrome Web Speech API' : 'Python Google Speech Recognition',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              if (_isWebPlatform) ...[
                const Text('🎯 To samo Google API co w Python script!\n'),
                const Text('✅ Jak używać w Chrome:'),
                const Text('1. Kliknij ikonę mikrofonu w pasku adresu'),
                const Text('2. Wybierz "Zawsze zezwalaj"'),
                const Text('3. Naciśnij MÓWIĘ i mów po polsku'),
                const Text('4. Chrome rozpozna wszystko na żywo!\n'),
                const Text('🔥 To prawdziwe rozpoznawanie Google, nie symulacja'),
                const Text('🎤 Działa offline po pierwszym połączeniu'),
                const Text('⚡ Szybkie i dokładne jak w Python'),
              ] else ...[
                const Text('🐍 Używa speech_recognizer.py\n'),
                const Text('✅ Wymagania:'),
                const Text('• Python 3.x zainstalowany'),
                const Text('• pip install SpeechRecognition'),
                const Text('• pip install sounddevice soundfile'),
                const Text('• pip install numpy\n'),
                const Text('🎤 Rozpoznaje polską mowę przez Google API'),
                const Text('📁 Plik speech_recognizer.py w głównym folderze'),
                const Text('🌐 Wymaga połączenia internetowego'),
              ],
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _isWebPlatform 
                    ? '💡 Tip: Mów naturalnie po polsku. Chrome rozpoznaje wszystko - od pojedynczych słów po długie zdania!'
                    : '💡 Tip: Mów wyraźnie po polsku. Python script użyje Google API do transkrypcji.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (_isWebPlatform)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _testConnection();
              },
              child: const Text('Test API'),
            ),
        ],
      ),
    );
  }

  void _testConnection() async {
    bool testResult = _isWebPlatform 
      ? await _chromeSpeechService.testConnection()
      : await _desktopSpeechService.testConnection();
    
    if (testResult) {
      _showSuccessSnackBar('✅ Test połączenia: OK');
    } else {
      _showErrorSnackBar('❌ Test połączenia: FAIL');
    }
  }

  @override
  void dispose() {
    if (_isWebPlatform) {
      _chromeSpeechService.dispose();
    } else {
      _desktopSpeechService.dispose();
    }
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isWebPlatform ? 'Rozpoznawanie mowy (Chrome)' : 'Rozpoznawanie mowy (Python)'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoHelp,
            tooltip: 'Informacje o rozpoznawaniu',
          ),
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearText,
            tooltip: 'Wyczyść tekst',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveTextAndReturn,
            tooltip: 'Użyj tekstu w notatce',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Informacja o serwisie
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isWebPlatform ? Colors.blue.shade100 : Colors.purple.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isWebPlatform ? Colors.blue : Colors.purple),
              ),
              child: Row(
                children: [
                  Icon(_isWebPlatform ? Icons.web : Icons.computer, 
                       color: _isWebPlatform ? Colors.blue : Colors.purple),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isWebPlatform 
                        ? '🌐 Chrome Web Speech API\n🎯 To samo Google API co w Python script!' 
                        : '🐍 Python Google Speech Recognition\n📁 Używa speech_recognizer.py',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            // Status inicjalizacji
            if (!_isInitialized)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Expanded(
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
                          fontSize: 14,
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
                    Expanded(
                      child: Text(
                        _isWebPlatform 
                          ? '🎤 Chrome nasłuchuje przez Google API... Mów po polsku!'
                          : '🎤 Python script nagrywa... Mów po polsku! (8s)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
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
                  label: Text(_isListening ? 'STOP' : 'MÓWIĘ'),
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

                // Przycisk Użyj tekstu
                ElevatedButton.icon(
                  onPressed: _textController.text.isNotEmpty ? _saveTextAndReturn : null,
                  icon: const Icon(Icons.check),
                  label: const Text('UŻYJ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
                ? (_isWebPlatform 
                  ? 'Naciśnij MÓWIĘ i powiedz cokolwiek po polsku!\nChrome używa tego samego Google API co Python script\n\n🔥 To prawdziwe rozpoznawanie na żywo!'
                  : 'Naciśnij MÓWIĘ i powiedz zdania po polsku (8s)\nPython script użyje Google API do transkrypcji\n\n🐍 Wymaga speech_recognizer.py w głównym folderze')
                : 'Inicjalizowanie...',
              style: TextStyle(
                fontSize: 12,
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