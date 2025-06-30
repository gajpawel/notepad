import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidSpeechService {
  static final AndroidSpeechService _instance = AndroidSpeechService._internal();
  factory AndroidSpeechService() => _instance;
  AndroidSpeechService._internal();

  static const MethodChannel _channel = MethodChannel('flutter_speech_recognition');
  
  bool _isListening = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  StreamSubscription? _speechSubscription;
  
  // Callback dla wyników
  Function(String)? onResult;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get recognizedText => _recognizedText;
  
  // Tylko Android wspiera to API
  bool get isPlatformSupported => defaultTargetPlatform == TargetPlatform.android;

  /// Inicjalizacja serwisu - Android Speech Recognition
  Future<bool> initialize() async {
    try {
      if (!isPlatformSupported) {
        onError?.call('Android Speech Service działa tylko na Androidzie');
        return false;
      }

      // Sprawdź czy device ma Speech Recognition
      bool isAvailable = await _channel.invokeMethod('isRecognitionAvailable');
      
      if (!isAvailable) {
        onError?.call('Rozpoznawanie mowy nie jest dostępne na tym urządzeniu');
        return false;
      }

      // Sprawdź uprawnienia do mikrofonu
      bool hasPermission = await _channel.invokeMethod('checkMicrophonePermission');
      
      if (!hasPermission) {
        // Poproś o uprawnienia
        bool granted = await _channel.invokeMethod('requestMicrophonePermission');
        if (!granted) {
          onError?.call('Brak uprawnień do mikrofonu. Udziel uprawnień w ustawieniach.');
          return false;
        }
      }

      // Ustaw listener dla wyników
      _channel.setMethodCallHandler(_handleMethodCall);

      _isInitialized = true;
      debugPrint('✅ Android Speech Service zainicjalizowany');
      return true;
      
    } catch (e) {
      onError?.call('Błąd inicjalizacji Android Speech API: ${e.toString()}');
      return false;
    }
  }

  /// Obsługa wywołań z natywnego kodu Android
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onSpeechResult':
        String result = call.arguments['text'] ?? '';
        bool isFinal = call.arguments['isFinal'] ?? false;
        
        debugPrint('📝 Android Speech: $result (final: $isFinal)');
        
        if (isFinal && result.trim().isNotEmpty) {
          _recognizedText = result.trim();
          onResult?.call(_recognizedText);
        }
        break;
        
      case 'onSpeechError':
        String error = call.arguments['error'] ?? 'Nieznany błąd';
        debugPrint('❌ Android Speech błąd: $error');
        
        String userFriendlyError = _getFriendlyError(error);
        onError?.call(userFriendlyError);
        
        _isListening = false;
        onListeningStateChanged?.call(false);
        break;
        
      case 'onListeningStarted':
        debugPrint('🎤 Android Speech: rozpoczęto nasłuchiwanie');
        _isListening = true;
        onListeningStateChanged?.call(true);
        break;
        
      case 'onListeningStopped':
        debugPrint('⏹️ Android Speech: zakończono nasłuchiwanie');
        _isListening = false;
        onListeningStateChanged?.call(false);
        break;
        
      case 'onPermissionResult':
        bool granted = call.arguments['granted'] ?? false;
        debugPrint('🔐 Android Permission result: $granted');
        if (!granted) {
          onError?.call('Uprawnienia do mikrofonu zostały odrzucone');
        }
        break;
    }
  }

  /// Konwertuj błędy Android na przyjazne komunikaty
  String _getFriendlyError(String error) {
    switch (error.toLowerCase()) {
      case 'error_audio':
        return 'Błąd nagrywania dźwięku. Sprawdź mikrofon.';
      case 'error_client':
        return 'Błąd aplikacji rozpoznawania mowy.';
      case 'error_insufficient_permissions':
        return 'Brak uprawnień do mikrofonu.';
      case 'error_network':
        return 'Błąd sieci. Sprawdź połączenie internetowe.';
      case 'error_network_timeout':
        return 'Timeout sieci. Spróbuj ponownie.';
      case 'error_no_match':
        return 'Nie rozpoznano mowy. Spróbuj mówić wyraźniej.';
      case 'error_recognizer_busy':
        return 'Rozpoznawanie jest zajęte. Spróbuj za chwilę.';
      case 'error_server':
        return 'Błąd serwera Google. Spróbuj ponownie.';
      case 'error_speech_timeout':
        return 'Nie wykryto mowy w określonym czasie.';
      default:
        return 'Błąd rozpoznawania: $error';
    }
  }

  /// Rozpocznij rozpoznawanie mowy przez Android API
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
      debugPrint('🎤 Android Speech: rozpoczynam nasłuchiwanie');
      debugPrint('🇵🇱 Język: $languageCode');
      
      // Wyczyść poprzednie wyniki
      _recognizedText = '';
      
      // Parametry dla Android Speech Recognition
      Map<String, dynamic> params = {
        'language': languageCode,
        'partialResults': true,  // Wyniki częściowe
        'continuous': true,      // Ciągłe nasłuchiwanie
        'maxResults': 1,         // Jeden najlepszy wynik
      };
      
      // Dodaj timeout jeśli podany (ale zwykle chcemy bez limitu)
      if (timeout != null) {
        params['timeoutMillis'] = timeout.inMilliseconds;
      }
      
      // Uruchom rozpoznawanie
      await _channel.invokeMethod('startListening', params);

    } catch (e) {
      onError?.call('Błąd uruchamiania Android Speech API: ${e.toString()}');
      _isListening = false;
      onListeningStateChanged?.call(false);
    }
  }

  /// Zatrzymaj nasłuchiwanie
  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _channel.invokeMethod('stopListening');
        debugPrint('⏹️ Android Speech: zatrzymano nasłuchiwanie');
      } catch (e) {
        debugPrint('❌ Błąd zatrzymywania: $e');
      }
    }
  }

  /// Anuluj nasłuchiwanie
  Future<void> cancelListening() async {
    try {
      await _channel.invokeMethod('cancelListening');
      _recognizedText = '';
      _isListening = false;
      onListeningStateChanged?.call(false);
      debugPrint('❌ Android Speech: anulowano nasłuchiwanie');
    } catch (e) {
      debugPrint('❌ Błąd anulowania: $e');
    }
  }

  /// Wyczyść rozpoznany tekst
  void clearText() {
    _recognizedText = '';
  }

  /// Test połączenia - sprawdź czy wszystko działa
  Future<bool> testConnection() async {
    if (!_isInitialized) return false;
    
    try {
      // Sprawdź dostępność usługi
      bool isAvailable = await _channel.invokeMethod('isRecognitionAvailable');
      
      // Sprawdź uprawnienia
      bool hasPermission = await _channel.invokeMethod('checkMicrophonePermission');
      
      return isAvailable && hasPermission;
    } catch (e) {
      debugPrint('❌ Test połączenia nieudany: $e');
      return false;
    }
  }

  /// Sprawdź informacje o platformie i Android Speech API
  Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': 'Android',
      'isSupported': isPlatformSupported,
      'isInitialized': _isInitialized,
      'isListening': _isListening,
      'service': 'Android Speech Recognition',
      'api_type': 'Google Speech Recognition (przez Android)',
      'language': 'pl-PL (wszystkie języki Android)',
      'features': [
        'Rozpoznawanie na żywo',
        'Wyniki częściowe i finalne', 
        'Ciągłe nasłuchiwanie',
        'Wiele języków',
        'Natywna wydajność',
        'Offline po pierwszym użyciu'
      ]
    };
  }

  /// Sprawdź dostępne języki (jeśli Android API to wspiera)
  Future<List<String>> getAvailableLanguages() async {
    try {
      if (!_isInitialized) return ['pl-PL'];
      
      final List<dynamic> languages = await _channel.invokeMethod('getAvailableLanguages');
      return languages.cast<String>();
    } catch (e) {
      debugPrint('❌ Błąd pobierania języków: $e');
      return ['pl-PL', 'en-US', 'en-GB', 'de-DE', 'fr-FR', 'es-ES', 'it-IT', 'ru-RU'];
    }
  }

  /// Sprawdź czy mikrofon jest dostępny
  Future<bool> isMicrophoneAvailable() async {
    try {
      if (!_isInitialized) return false;
      
      bool hasPermission = await _channel.invokeMethod('checkMicrophonePermission');
      return hasPermission;
    } catch (e) {
      debugPrint('❌ Błąd sprawdzania mikrofonu: $e');
      return false;
    }
  }

  /// Poproś ponownie o uprawnienia (jeśli user odrzucił wcześniej)
  Future<bool> requestPermissions() async {
    try {
      if (!_isInitialized) return false;
      
      bool granted = await _channel.invokeMethod('requestMicrophonePermission');
      return granted;
    } catch (e) {
      debugPrint('❌ Błąd żądania uprawnień: $e');
      return false;
    }
  }

  /// Sprawdź czy urządzenie ma Speech Recognition
  Future<bool> isRecognitionAvailable() async {
    try {
      bool available = await _channel.invokeMethod('isRecognitionAvailable');
      return available;
    } catch (e) {
      debugPrint('❌ Błąd sprawdzania dostępności: $e');
      return false;
    }
  }

  /// Zwolnij zasoby
  void dispose() {
    try {
      if (_isListening) {
        _channel.invokeMethod('cancelListening');
      }
      
      _speechSubscription?.cancel();
      
      // Usuń handler
      _channel.setMethodCallHandler(null);
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