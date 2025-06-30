import 'dart:async';
import 'package:flutter/foundation.dart';

// Conditional import dla dart:js - tylko na Web
import 'dart:js' as js if (dart.library.io) 'dart:core';

class ChromeSpeechService {
  static final ChromeSpeechService _instance = ChromeSpeechService._internal();
  factory ChromeSpeechService() => _instance;
  ChromeSpeechService._internal();

  bool _isListening = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  
  // Callback dla wyników
  Function(String)? onResult;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get recognizedText => _recognizedText;
  
  // Tylko Web wspiera Web Speech API
  bool get isPlatformSupported => kIsWeb;

  /// Inicjalizacja serwisu - JavaScript API (tylko Web)
  Future<bool> initialize() async {
    try {
      if (!kIsWeb) {
        debugPrint('ChromeSpeechService: Nie-Web platforma - wyłączony');
        return false;
      }

      // Sprawdź czy dart:js jest dostępny
      if (!_isJsAvailable()) {
        onError?.call('JavaScript context nie jest dostępny');
        return false;
      }

      // Wstrzyknij JavaScript code bezpośrednio
      _injectJavaScript();

      // Ustaw Dart callbacks
      _setupCallbacks();

      // Sprawdź czy inicjalizacja się udała
      bool initResult = _callJsMethod('init');
      
      if (initResult) {
        _isInitialized = true;
        debugPrint('✅ JavaScript Speech Service zainicjalizowany');
        return true;
      } else {
        onError?.call('Przeglądarka nie wspiera Web Speech API');
        return false;
      }
      
    } catch (e) {
      onError?.call('Błąd inicjalizacji JavaScript API: ${e.toString()}');
      return false;
    }
  }

  /// Sprawdź czy JavaScript context jest dostępny
  bool _isJsAvailable() {
    try {
      // Na Web dart:js powinien być dostępny
      return kIsWeb && js.context != null;
    } catch (e) {
      debugPrint('❌ dart:js nie jest dostępny: $e');
      return false;
    }
  }

  /// Wywołaj metodę JavaScript bezpiecznie
  bool _callJsMethod(String method, [List<dynamic>? args]) {
    try {
      if (!_isJsAvailable()) return false;
      
      var speechRecognition = js.context['flutterSpeechRecognition'];
      if (speechRecognition == null) return false;
      
      if (args != null) {
        return speechRecognition.callMethod(method, args);
      } else {
        return speechRecognition.callMethod(method);
      }
    } catch (e) {
      debugPrint('❌ Błąd wywołania JS metody $method: $e');
      return false;
    }
  }

  /// Wstrzyknij JavaScript kod
  void _injectJavaScript() {
    try {
      js.context.callMethod('eval', ['''
        window.flutterSpeechRecognition = {
          recognition: null,
          isListening: false,
          
          init: function() {
            try {
              if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
                console.error('Web Speech API nie jest wspierane');
                return false;
              }
              
              const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
              this.recognition = new SpeechRecognition();
              
              this.recognition.continuous = true;
              this.recognition.interimResults = true;
              this.recognition.lang = 'pl-PL';
              
              // Callbacks
              this.recognition.onstart = () => {
                console.log('🎤 JavaScript: Rozpoczęto nasłuchiwanie');
                this.isListening = true;
                if (window.flutterSpeechCallbacks && window.flutterSpeechCallbacks.onStart) {
                  window.flutterSpeechCallbacks.onStart();
                }
              };
              
              this.recognition.onend = () => {
                console.log('⏹️ JavaScript: Zakończono nasłuchiwanie');
                this.isListening = false;
                if (window.flutterSpeechCallbacks && window.flutterSpeechCallbacks.onEnd) {
                  window.flutterSpeechCallbacks.onEnd();
                }
              };
              
              this.recognition.onresult = (event) => {
                console.log('🔍 JavaScript: Otrzymano wynik');
                
                try {
                  for (let i = event.resultIndex; i < event.results.length; i++) {
                    const result = event.results[i];
                    const transcript = result[0].transcript;
                    const isFinal = result.isFinal;
                    
                    console.log('📝 Transcript:', transcript, 'Final:', isFinal);
                    
                    if (isFinal && transcript.trim().length > 0) {
                      console.log('✅ Wysyłam do Flutter:', transcript);
                      if (window.flutterSpeechCallbacks && window.flutterSpeechCallbacks.onResult) {
                        window.flutterSpeechCallbacks.onResult(transcript.trim());
                      }
                    }
                  }
                } catch (e) {
                  console.error('❌ Błąd przetwarzania wyniku:', e);
                }
              };
              
              this.recognition.onerror = (event) => {
                console.error('❌ JavaScript Speech błąd:', event.error);
                let errorMsg = 'Błąd rozpoznawania: ' + event.error;
                
                switch(event.error) {
                  case 'not-allowed':
                    errorMsg = 'Brak uprawnień do mikrofonu. Kliknij ikonę mikrofonu w pasku adresu.';
                    break;
                  case 'no-speech':
                    errorMsg = 'Nie wykryto mowy. Spróbuj mówić wyraźniej.';
                    break;
                  case 'audio-capture':
                    errorMsg = 'Mikrofon niedostępny. Sprawdź połączenie mikrofonu.';
                    break;
                  case 'network':
                    errorMsg = 'Błąd sieci. Sprawdź połączenie internetowe.';
                    break;
                }
                
                if (window.flutterSpeechCallbacks && window.flutterSpeechCallbacks.onError) {
                  window.flutterSpeechCallbacks.onError(errorMsg);
                }
              };
              
              console.log('✅ Web Speech API zainicjalizowane');
              return true;
            } catch (e) {
              console.error('❌ Błąd inicjalizacji:', e);
              return false;
            }
          },
          
          start: function(language) {
            if (!this.recognition) return false;
            try {
              this.recognition.lang = language || 'pl-PL';
              this.recognition.start();
              return true;
            } catch (e) {
              console.error('❌ Błąd start:', e);
              return false;
            }
          },
          
          stop: function() {
            if (!this.recognition) return;
            try {
              this.recognition.stop();
            } catch (e) {
              console.error('❌ Błąd stop:', e);
            }
          },
          
          abort: function() {
            if (!this.recognition) return;
            try {
              this.recognition.abort();
            } catch (e) {
              console.error('❌ Błąd abort:', e);
            }
          }
        };
        
        console.log('🚀 Flutter Speech Recognition JavaScript injected');
      ''']);
    } catch (e) {
      debugPrint('❌ Błąd wstrzykiwania JavaScript: $e');
    }
  }

  /// Ustaw Dart callbacks
  void _setupCallbacks() {
    try {
      js.context['flutterSpeechCallbacks'] = js.JsObject.jsify({
        'onStart': () {
          debugPrint('🎤 Dart: Otrzymano onStart');
          _isListening = true;
          onListeningStateChanged?.call(true);
        },
        'onEnd': () {
          debugPrint('⏹️ Dart: Otrzymano onEnd');
          _isListening = false;
          onListeningStateChanged?.call(false);
        },
        'onResult': (String text) {
          debugPrint('✅ Dart: Otrzymano wynik: "$text"');
          _recognizedText = text;
          onResult?.call(text);
        },
        'onError': (String error) {
          debugPrint('❌ Dart: Otrzymano błąd: "$error"');
          onError?.call(error);
          _isListening = false;
          onListeningStateChanged?.call(false);
        },
      });
    } catch (e) {
      debugPrint('❌ Błąd ustawiania callbacks: $e');
    }
  }

  /// Rozpocznij rozpoznawanie mowy
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

    try {
      debugPrint('🎤 Dart: Rozpoczynam nasłuchiwanie (język: $languageCode)');
      
      // Wyczyść poprzednie wyniki
      _recognizedText = '';
      
      // Uruchom JavaScript funkcję
      bool started = _callJsMethod('start', [languageCode]);
      
      if (!started) {
        onError?.call('Nie można uruchomić rozpoznawania');
        return;
      }
      
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
      onError?.call('Błąd uruchamiania: ${e.toString()}');
      _isListening = false;
      onListeningStateChanged?.call(false);
    }
  }

  /// Zatrzymaj nasłuchiwanie
  Future<void> stopListening() async {
    if (_isListening) {
      try {
        _callJsMethod('stop');
        debugPrint('⏹️ Dart: Zatrzymano nasłuchiwanie');
      } catch (e) {
        debugPrint('❌ Błąd zatrzymywania: $e');
      }
    }
  }

  /// Anuluj nasłuchiwanie
  Future<void> cancelListening() async {
    try {
      _callJsMethod('abort');
      _recognizedText = '';
      _isListening = false;
      onListeningStateChanged?.call(false);
      debugPrint('❌ Dart: Anulowano nasłuchiwanie');
    } catch (e) {
      debugPrint('❌ Błąd anulowania: $e');
    }
  }

  /// Wyczyść rozpoznany tekst
  void clearText() {
    _recognizedText = '';
  }

  /// Test połączenia
  Future<bool> testConnection() async {
    if (!_isInitialized) return false;
    
    try {
      // Prosta próba dostępu do mikrofonu
      return _isJsAvailable();
    } catch (e) {
      debugPrint('❌ Test połączenia nieudany: $e');
      return false;
    }
  }

  /// Sprawdź informacje o platformie
  Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': 'Web',
      'isSupported': isPlatformSupported,
      'isInitialized': _isInitialized,
      'isListening': _isListening,
      'service': 'JavaScript Web Speech API',
      'api_type': 'Native JavaScript SpeechRecognition',
      'language': 'pl-PL',
      'features': [
        'Rozpoznawanie na żywo',
        'Wyniki finalne', 
        'Automatyczne wykrywanie ciszy',
        'Wiele języków',
        'Bezpośrednie JavaScript API'
      ]
    };
  }

  /// Zwolnij zasoby
  void dispose() {
    try {
      if (_isListening) {
        _callJsMethod('abort');
      }
      
      // Usuń callbacks
      if (_isJsAvailable()) {
        js.context.deleteProperty('flutterSpeechCallbacks');
      }
    } catch (e) {
      debugPrint('❌ Błąd dispose: $e');
    }
    
    _isListening = false;
    _isInitialized = false;
    onResult = null;
    onError = null;
    onListeningStateChanged = null;
  }
}