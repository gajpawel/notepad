import 'dart:async';

/// Dummy ChromeSpeechService dla platform nie-Web
/// Używany przez conditional import żeby uniknąć problemów z dart:js na Desktop/Android
class ChromeSpeechService {
  static final ChromeSpeechService _instance = ChromeSpeechService._internal();
  factory ChromeSpeechService() => _instance;
  ChromeSpeechService._internal();

  bool _isListening = false;
  bool _isInitialized = false;
  String _recognizedText = '';
  
  // Callback dla wyników (dummy)
  Function(String)? onResult;
  Function(String)? onError;
  Function(bool)? onListeningStateChanged;

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get recognizedText => _recognizedText;
  
  // Na Desktop/Android nie wspiera Web Speech API
  bool get isPlatformSupported => false;

  /// Dummy inicjalizacja - zawsze zwraca false
  Future<bool> initialize() async {
    print('🚫 Dummy ChromeSpeechService: nie inicjalizuje na tej platformie');
    return false;
  }

  /// Dummy startListening - nic nie robi
  Future<void> startListening({
    String languageCode = 'pl-PL',
    Duration? timeout,
  }) async {
    print('🚫 Dummy ChromeSpeechService: startListening nie dostępny');
    onError?.call('Chrome Speech Service nie jest dostępny na tej platformie');
  }

  /// Dummy stopListening - nic nie robi
  Future<void> stopListening() async {
    print('🚫 Dummy ChromeSpeechService: stopListening nie dostępny');
  }

  /// Dummy cancelListening - nic nie robi
  Future<void> cancelListening() async {
    print('🚫 Dummy ChromeSpeechService: cancelListening nie dostępny');
    _recognizedText = '';
    _isListening = false;
    onListeningStateChanged?.call(false);
  }

  /// Dummy clearText - nic nie robi
  void clearText() {
    _recognizedText = '';
  }

  /// Dummy testConnection - zawsze zwraca false
  Future<bool> testConnection() async {
    return false;
  }

  /// Dummy informacje o platformie
  Map<String, dynamic> getPlatformInfo() {
    return {
      'platform': 'Desktop/Android',
      'isSupported': false,
      'isInitialized': false,
      'isListening': false,
      'service': 'Dummy Chrome Speech Service',
      'api_type': 'Not Available',
      'language': 'N/A',
      'features': []
    };
  }

  /// Dummy dispose - nic nie robi
  void dispose() {
    _isListening = false;
    _isInitialized = false;
    onResult = null;
    onError = null;
    onListeningStateChanged = null;
  }
}