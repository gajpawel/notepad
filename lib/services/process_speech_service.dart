import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ProcessSpeechService {
  static final ProcessSpeechService _instance = ProcessSpeechService._internal();
  factory ProcessSpeechService() => _instance;
  ProcessSpeechService._internal();

  bool _isListening = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  String _pythonScriptPath = '';
  
  // Callback dla wyników
  Function(String)? onResult;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get recognizedText => _recognizedText;
  
  // Wspiera wszystkie platformy gdzie Python jest dostępny
  bool get isPlatformSupported => !kIsWeb; // Web nie może uruchamiać procesów

  /// Inicjalizacja serwisu - znajdź Python script
  Future<bool> initialize() async {
    try {
      if (kIsWeb) {
        onError?.call('Process Speech Service nie działa na Web. Użyj Chrome wersji.');
        return false;
      }

      // Znajdź ścieżkę do Python script
      List<String> possiblePaths = [
        'speech_recognizer.py',                    // W folderze aplikacji
        '../speech_recognizer.py',                 // Folder wyżej
        '../../speech_recognizer.py',              // Dwa foldery wyżej
        './assets/scripts/speech_recognizer.py',   // W assets
      ];
      
      // Sprawdź względem obecnego folderu roboczego
      String currentDir = Directory.current.path;
      debugPrint('📁 Obecny folder: $currentDir');
      
      for (String path in possiblePaths) {
        File scriptFile = File(path);
        debugPrint('🔍 Sprawdzam: ${scriptFile.absolute.path}');
        
        if (await scriptFile.exists()) {
          _pythonScriptPath = scriptFile.absolute.path;
          debugPrint('✅ Znaleziono Python script: $_pythonScriptPath');
          break;
        }
      }
      
      if (_pythonScriptPath.isEmpty) {
        onError?.call('Nie znaleziono pliku speech_recognizer.py\nUmieść go w folderze projektu');
        return false;
      }
      
      // Sprawdź czy Python jest dostępny
      bool pythonAvailable = await _checkPythonAvailability();
      if (!pythonAvailable) {
        onError?.call('Python nie jest dostępny. Zainstaluj Python 3.x');
        return false;
      }
      
      _isInitialized = true;
      debugPrint('✅ Process Speech Service zainicjalizowany');
      return true;
      
    } catch (e) {
      onError?.call('Błąd inicjalizacji: ${e.toString()}');
      return false;
    }
  }

  /// Sprawdź czy Python jest dostępny w systemie
  Future<bool> _checkPythonAvailability() async {
    List<String> pythonCommands = ['python', 'python3', 'py'];
    
    for (String cmd in pythonCommands) {
      try {
        ProcessResult result = await Process.run(
          cmd, 
          ['--version'],
          runInShell: true,
        ).timeout(const Duration(seconds: 5));
        
        if (result.exitCode == 0) {
          String version = result.stdout.toString().trim();
          debugPrint('✅ Znaleziono Python: $cmd -> $version');
          return true;
        }
      } catch (e) {
        debugPrint('❌ $cmd nie działa: $e');
        continue;
      }
    }
    
    return false;
  }

  /// Rozpocznij rozpoznawanie mowy przez Python script
  Future<void> startListening({
    String languageCode = 'pl-PL',
    Duration? timeout,
  }) async {
    if (!_isInitialized) {
      onError?.call('Serwis nie został zainicjalizowany');
      return;
    }

    if (_isListening) {
      return; // Już nasłuchuje
    }

    _isListening = true;
    onListeningStateChanged?.call(true);

    try {
      int durationSeconds = timeout?.inSeconds ?? 8;
      
      debugPrint('🐍 Uruchamiam Python script...');
      debugPrint('📝 Ścieżka: $_pythonScriptPath');
      debugPrint('⏱️ Czas: ${durationSeconds}s, Język: $languageCode');
      
      // Uruchom Python script z argumentami
      List<String> arguments = [
        _pythonScriptPath,
        '--duration', durationSeconds.toString(),
        '--language', languageCode,
        '--mode', 'auto',  // Automatycznie wybierze real lub simulate
      ];
      
      ProcessResult result = await Process.run(
        'python',
        arguments,
        runInShell: true,
      ).timeout(Duration(seconds: durationSeconds + 10));

      _isListening = false;
      onListeningStateChanged?.call(false);

      debugPrint('🔚 Python script zakończony');
      debugPrint('📤 Exit code: ${result.exitCode}');
      debugPrint('📤 Stdout: ${result.stdout}');
      debugPrint('📤 Stderr: ${result.stderr}');

      if (result.exitCode == 0) {
        String output = result.stdout.toString().trim();
        
        if (output.isNotEmpty) {
          try {
            // Parse JSON output
            Map<String, dynamic> data = jsonDecode(output);
            
            if (data['success'] == true && data['text'] != null) {
              _recognizedText = data['text'];
              onResult?.call(_recognizedText);
              
              debugPrint('✅ Rozpoznano: $_recognizedText');
              debugPrint('🇵🇱 Język: ${data['language']}');
              debugPrint('📊 Pewność: ${data['confidence']}');
              debugPrint('⚙️ Metoda: ${data['method'] ?? 'simulation'}');
            } else if (data['error'] != null) {
              onError?.call('Python script: ${data['error']}');
            } else {
              onError?.call('Nie rozpoznano mowy');
            }
          } catch (e) {
            onError?.call('Błąd parsowania wyniku Python: ${e.toString()}');
          }
        } else {
          onError?.call('Python script nie zwrócił wyniku');
        }
      } else {
        String errorOutput = result.stderr.toString();
        onError?.call('Python script błąd (exit: ${result.exitCode})\n$errorOutput');
      }

    } catch (e) {
      _isListening = false;
      onListeningStateChanged?.call(false);
      
      if (e is TimeoutException) {
        onError?.call('Timeout - Python script nie odpowiedział w czasie');
      } else {
        onError?.call('Błąd uruchamiania Python script: ${e.toString()}');
      }
    }
  }

  /// Zatrzymaj nasłuchiwanie (trudne z procesem, ale można spróbować)
  Future<void> stopListening() async {
    if (_isListening) {
      // Dla process-based approach trudno zatrzymać w połowie
      debugPrint('ℹ️ Python script ma wbudowany timeout, czekaj na zakończenie');
    }
  }

  /// Anuluj nasłuchiwanie
  Future<void> cancelListening() async {
    if (_isListening) {
      _isListening = false;
      _recognizedText = '';
      onListeningStateChanged?.call(false);
      debugPrint('❌ Anulowano nasłuchiwanie');
    }
  }

  /// Wyczyść rozpoznany tekst
  void clearText() {
    _recognizedText = '';
  }

  /// Sprawdź informacje o platformie i Python
  Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': _getPlatformName(),
      'isWeb': kIsWeb,
      'isSupported': isPlatformSupported,
      'isInitialized': _isInitialized,
      'isListening': _isListening,
      'service': 'Process-based Python Speech Recognition',
      'python_script': _pythonScriptPath,
      'language': 'pl-PL (forced)',
    };
  }

  /// Pobierz nazwę platformy
  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Sprawdź czy można uruchomić Python script
  Future<bool> testPythonScript() async {
    if (!_isInitialized) return false;
    
    try {
      ProcessResult result = await Process.run(
        'python',
        [_pythonScriptPath, '--duration', '1', '--mode', 'simulate'],
        runInShell: true,
      ).timeout(const Duration(seconds: 10));
      
      return result.exitCode == 0;
    } catch (e) {
      debugPrint('❌ Test Python script failed: $e');
      return false;
    }
  }

  /// Test połączenia - sprawdź czy Python i script działają
  Future<bool> testConnection() async {
    return await testPythonScript();
  }

  /// Zwolnij zasoby
  void dispose() {
    _isListening = false;
    _isInitialized = false;
    onResult = null;
    onError = null;
    onListeningStateChanged = null;
  }
}