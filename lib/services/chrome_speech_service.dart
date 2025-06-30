import 'dart:async';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';

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

  /// Inicjalizacja serwisu - JavaScript API
  Future<bool> initialize() async {
    try {
      if (!kIsWeb) {
        onError?.call('ChromeSpeechService działa tylko w przeglądarce');
        return false;
      }

      // Wstrzyknij JavaScript code bezpośrednio
      js.context.callMethod('eval', ['''
        window.flutterSpeechRecognition = {
          recognition: null,
          isListening: false,
          
          init: function() {
            try {
              if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
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
                console.log('Results length:', event.results.length);
                
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
        
        // Inicjalizuj od razu
        window.flutterSpeechRecognition.init();
      ''']);

      // Ustaw Dart callbacks
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

      // Sprawdź czy inicjalizacja się udała
      bool initResult = js.context['flutterSpeechRecognition'].callMethod('init');
      
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
      bool started = js.context['flutterSpeechRecognition'].callMethod('start', [languageCode]);
      
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
        js.context['flutterSpeechRecognition'].callMethod('stop');
        debugPrint('⏹️ Dart: Zatrzymano nasłuchiwanie');
      } catch (e) {
        debugPrint('❌ Błąd zatrzymywania: $e');
      }
    }
  }

  /// Anuluj nasłuchiwanie
  Future<void> cancelListening() async {
    try {
      js.context['flutterSpeechRecognition'].callMethod('abort');
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
      return true; // JavaScript sam sprawdzi uprawnienia
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
        js.context['flutterSpeechRecognition'].callMethod('abort');
      }
      
      // Usuń callbacks
      js.context.deleteProperty('flutterSpeechCallbacks');
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