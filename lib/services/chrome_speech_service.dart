import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class ChromeSpeechService {
  static final ChromeSpeechService _instance = ChromeSpeechService._internal();
  factory ChromeSpeechService() => _instance;
  ChromeSpeechService._internal();

  bool _isListening = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  html.SpeechRecognition? _speechRecognition;
  
  // Callback dla wyników
  Function(String)? onResult;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get recognizedText => _recognizedText;
  
  // Tylko Web wspiera Web Speech API
  bool get isPlatformSupported => kIsWeb;

  /// Inicjalizacja serwisu - Web Speech API
  Future<bool> initialize() async {
    try {
      if (!kIsWeb) {
        onError?.call('ChromeSpeechService działa tylko w przeglądarce');
        return false;
      }

      // Sprawdź czy przeglądarka wspiera Web Speech API
      if (!_isSpeechRecognitionSupported()) {
        onError?.call('Przeglądarka nie wspiera Web Speech API\nUżyj Chrome, Edge lub Safari');
        return false;
      }

      // Inicjalizuj Web Speech API
      _speechRecognition = html.SpeechRecognition();
      
      if (_speechRecognition == null) {
        onError?.call('Nie udało się utworzyć obiektu SpeechRecognition');
        return false;
      }

      // Skonfiguruj Speech Recognition
      _speechRecognition!.continuous = true;
      _speechRecognition!.interimResults = true;
      
      // Ustaw callback'i
      _speechRecognition!.onStart.listen((event) {
        debugPrint('🎤 Chrome Speech API: rozpoczęto nasłuchiwanie');
        _isListening = true;
        onListeningStateChanged?.call(true);
      });

      _speechRecognition!.onEnd.listen((event) {
        debugPrint('⏹️ Chrome Speech API: zakończono nasłuchiwanie');
        _isListening = false;
        onListeningStateChanged?.call(false);
      });

      _speechRecognition!.onResult.listen((event) {
        try {
          debugPrint('🔍 Raw result event: $event');
          final results = event.results;
          debugPrint('🔍 Results length: ${results?.length}');
          
          if (results != null && results.length > 0) {
            // Pobierz ostatni wynik
            final result = results[results.length - 1];
            debugPrint('🔍 Result object: $result');
            
            if (result != null) {
              final isFinal = result.isFinal ?? false;
              debugPrint('🔍 isFinal: $isFinal');
              
              // POPRAWIONA OBSŁUGA - używamy tylko item(0)
              try {
                // Sprawdź czy result ma jakiekolwiek alternatywy
                final resultLength = result.length;
                debugPrint('🔍 Result length: $resultLength');
                
                if (resultLength != null && resultLength > 0) {
                  final alternative = result.item(0);
                  if (alternative != null) {
                    final transcript = alternative.transcript ?? '';
                    debugPrint('📝 Chrome Speech: ${isFinal ? "FINAL" : "interim"}: $transcript');
                    
                    // Tylko finalne wyniki przekazuj do callback
                    if (isFinal && transcript.isNotEmpty) {
                      _recognizedText = transcript;
                      onResult?.call(_recognizedText);
                    }
                  } else {
                    debugPrint('❌ alternative is null');
                  }
                } else {
                  debugPrint('❌ Result length is 0 or null');
                }
              } catch (itemError) {
                debugPrint('⚠️ item(0) failed: $itemError');
                
                // Fallback - spróbuj prostszego dostępu przez toString()
                try {
                  final transcript = result.toString();
                  debugPrint('📝 Chrome Speech (toString fallback): ${isFinal ? "FINAL" : "interim"}: $transcript');
                  
                  // Sprawdź czy toString zwrócił sensowny tekst
                  if (isFinal && transcript.isNotEmpty && 
                      !transcript.contains('Instance of') && 
                      !transcript.contains('SpeechRecognitionResult')) {
                    _recognizedText = transcript;
                    onResult?.call(_recognizedText);
                  }
                } catch (toStringError) {
                  debugPrint('❌ toString fallback failed: $toStringError');
                }
              }
            } else {
              debugPrint('❌ result is null');
            }
          } else {
            debugPrint('❌ results is null or empty');
          }
        } catch (e) {
          debugPrint('❌ Błąd przetwarzania wyniku: $e');
          onError?.call('Błąd przetwarzania wyniku rozpoznawania: ${e.toString()}');
        }
      });

      _speechRecognition!.onError.listen((event) {
        final error = event.error ?? 'Nieznany błąd';
        debugPrint('❌ Chrome Speech API błąd: $error');
        
        String userFriendlyError;
        switch (error) {
          case 'not-allowed':
            userFriendlyError = 'Brak uprawnień do mikrofonu.\nKliknij ikonę mikrofonu w pasku adresu i wybierz "Zawsze zezwalaj"';
            break;
          case 'no-speech':
            userFriendlyError = 'Nie wykryto mowy. Spróbuj ponownie i mów wyraźniej';
            break;
          case 'audio-capture':
            userFriendlyError = 'Mikrofon niedostępny. Sprawdź czy mikrofon jest podłączony';
            break;
          case 'network':
            userFriendlyError = 'Błąd sieci. Sprawdź połączenie internetowe';
            break;
          case 'aborted':
            userFriendlyError = 'Rozpoznawanie zostało przerwane';
            break;
          default:
            userFriendlyError = 'Błąd Web Speech API: $error';
        }
        
        onError?.call(userFriendlyError);
        _isListening = false;
        onListeningStateChanged?.call(false);
      });

      _isInitialized = true;
      debugPrint('✅ Chrome Speech Service zainicjalizowany');
      return true;
      
    } catch (e) {
      onError?.call('Błąd inicjalizacji Chrome Speech API: ${e.toString()}');
      return false;
    }
  }

  /// Sprawdź czy przeglądarka wspiera Web Speech API
  bool _isSpeechRecognitionSupported() {
    try {
      // Sprawdź czy SpeechRecognition istnieje w kontekście przeglądarki
      return html.window.navigator.userAgent.contains('Chrome') ||
             html.window.navigator.userAgent.contains('Edge') ||
             html.window.navigator.userAgent.contains('Safari');
    } catch (e) {
      return false;
    }
  }

  /// Rozpocznij rozpoznawanie mowy przez Web Speech API
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

    if (_speechRecognition == null) {
      onError?.call('Speech Recognition nie jest dostępny');
      return;
    }

    try {
      debugPrint('🎤 Chrome Speech API: rozpoczynam nasłuchiwanie');
      debugPrint('🇵🇱 Język: $languageCode');
      
      // Ustaw język
      _speechRecognition!.lang = languageCode;
      
      // Uruchom rozpoznawanie
      _speechRecognition!.start();
      
      // Ustaw timeout jeśli podany
      if (timeout != null) {
        Timer(timeout, () {
          if (_isListening) {
            debugPrint('⏰ Timeout - zatrzymuję nasłuchiwanie');
            stopListening();
          }
        });
      }

    } catch (e) {
      onError?.call('Błąd uruchamiania Web Speech API: ${e.toString()}');
      _isListening = false;
      onListeningStateChanged?.call(false);
    }
  }

  /// Zatrzymaj nasłuchiwanie
  Future<void> stopListening() async {
    if (_speechRecognition != null && _isListening) {
      try {
        _speechRecognition!.stop();
        debugPrint('⏹️ Chrome Speech API: zatrzymano nasłuchiwanie');
      } catch (e) {
        debugPrint('❌ Błąd zatrzymywania: $e');
      }
    }
  }

  /// Anuluj nasłuchiwanie
  Future<void> cancelListening() async {
    if (_speechRecognition != null && _isListening) {
      try {
        _speechRecognition!.abort();
        _recognizedText = '';
        debugPrint('❌ Chrome Speech API: anulowano nasłuchiwanie');
      } catch (e) {
        debugPrint('❌ Błąd anulowania: $e');
      }
    }
  }

  /// Wyczyść rozpoznany tekst
  void clearText() {
    _recognizedText = '';
  }

  /// Test połączenia - sprawdź uprawnienia mikrofonu
  Future<bool> testConnection() async {
    if (!_isInitialized) return false;
    
    try {
      // Sprawdź uprawnienia do mikrofonu
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices != null) {
        try {
          final stream = await mediaDevices.getUserMedia({'audio': true});
          // Zatrzymaj stream natychmiast
          stream.getTracks().forEach((track) => track.stop());
          return true;
        } catch (e) {
          debugPrint('❌ Brak uprawnień do mikrofonu: $e');
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('❌ Test połączenia nieudany: $e');
      return false;
    }
  }

  /// Sprawdź informacje o platformie i Web Speech API
  Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': 'Web',
      'browser': html.window.navigator.userAgent,
      'isSupported': isPlatformSupported && _isSpeechRecognitionSupported(),
      'isInitialized': _isInitialized,
      'isListening': _isListening,
      'service': 'Chrome Web Speech API',
      'api_type': 'Google Speech Recognition (przez Chrome)',
      'language': 'pl-PL (dostępne wszystkie języki)',
      'features': [
        'Rozpoznawanie na żywo',
        'Wyniki częściowe i finalne', 
        'Automatyczne wykrywanie ciszy',
        'Wiele języków',
        'Wysoka dokładność'
      ]
    };
  }

  /// Zwolnij zasoby
  void dispose() {
    if (_speechRecognition != null && _isListening) {
      _speechRecognition!.abort();
    }
    
    _isListening = false;
    _isInitialized = false;
    _speechRecognition = null;
    onResult = null;
    onError = null;
    onListeningStateChanged = null;
  }
}