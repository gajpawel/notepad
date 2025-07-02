# Noteable 📝

Zaawansowany notatnik napisany we Flutterze z funkcjami rozpoznawania mowy i tekstu z obrazów. Aplikacja wykorzystuje Firebase do przechowywania danych i oferuje wieloplatformową synchronizację.

## ✨ Główne funkcje

- 📱 **Wieloplatformowość** - Android, Web (Chrome)
- 🎤 **Rozpoznawanie mowy** - dwie implementacje:
  - **Android**: Natywne Android Speech Recognition API
  - **Web**: Chrome Web Speech API (JavaScript)
- 📸 **OCR (rozpoznawanie tekstu z obrazów)**:
  - **Web**: Tesseract.js
  - **Mobile**: Google ML Kit
- ☁️ **Synchronizacja w chmurze** - Firebase Realtime Database
- 👥 **Współdzielenie notatek** - system współtwórców
- 📁 **Organizacja w folderach** - hierarchiczna struktura
- 🗑️ **Kosz** - z automatycznym usuwaniem po 30 dniach
- 📋 **Kopiowanie/Wklejanie** - notatek i folderów
- 💾 **Eksport** - notatki jako pliki tekstowe, foldery jako ZIP
- 🔐 **Uwierzytelnianie** - Firebase Auth z weryfikacją email

## 🚀 Technologie

**Frontend:**
- **Flutter** 3.x - główny framework
- **Flutter Quill** - edytor tekstu sformatowanego
- **Firebase SDK** - autentykacja i baza danych

**Backend:**
- **Firebase Authentication** - zarządzanie użytkownikami
- **Firebase Realtime Database** - przechowywanie danych
- **Firebase Hosting** - hosting aplikacji webowej

**Rozpoznawanie mowy:**
- **Android**: Native Speech Recognition
- **Web**: Web Speech API (Chrome)

**OCR:**
- **Web**: Tesseract.js
- **Mobile**: Google ML Kit Text Recognition

## 📱 Platformy i wymagania

### ✅ Android
- **API Level**: 23+ (Android 6.0+)
- **Uprawnienia**: Mikrofon, Storage
- **Funkcje**: Pełna funkcjonalność + natywne Speech API

### ✅ Web (Chrome)
- **Przeglądarki**: Chrome, Edge (Chromium-based)
- **HTTPS**: Wymagane dla mikrofonu
- **Funkcje**: Web Speech API + Tesseract.js OCR

### 🔄 Desktop (Windows/macOS/Linux) - W planach
- **Status**: Firebase compatibility issues - implementacja planowana
- **Dostępne**: Tylko podstawowe funkcje Flutter (bez speech/OCR/sync)

## 🛠️ Instalacja i uruchomienie

### Wymagania
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Android Studio / VS Code
- Python 3.x (dla funkcji desktop)

### 1. Sklonuj repozytorium
```bash
git clone https://github.com/gajpawel/notepad
cd noteable
```

### 2. Konfiguracja Firebase
Projekt używa gotowej konfiguracji Firebase:
- **Project ID**: `notepaddb-5e65b`
- **Database**: Europe West 1
- **Auth**: Email/Password z weryfikacją

### 3. Zainstaluj zależności Flutter
```bash
flutter pub get
```

### 4. (Opcjonalnie) Przygotowanie środowisk

**Dla Android:**
- Android Studio z emulatorami
- Fizyczne urządzenie Android

**Dla Web:**
- Chrome/Edge browser
- HTTPS development server

### 5. Uruchom aplikację

**Android:**
```bash
flutter run
```

**Web:**
```bash
flutter run -d chrome
```

**Desktop:** (W planach)
```bash
# Obecnie niedostępne z powodu problemów z Firebase
# Implementacja planowana w przyszłych wersjach
```

## 🎯 Instrukcja użytkowania

### 🔐 Rejestracja i logowanie
1. Uruchom aplikację
2. Kliknij "Nie masz konta? Zarejestruj się"
3. Wypełnij formularz rejestracji
4. Sprawdź email i zweryfikuj konto
5. Zaloguj się swoimi danymi

### 📝 Tworzenie notatek
1. Kliknij przycisk "+" (dolny prawy róg)
2. Nadaj nazwę notatce  
3. Użyj edytora Quill do formatowania tekstu

### 🎤 Rozpoznawanie mowy
1. **W edytorze notatki**: kliknij ikonę mikrofonu
2. **Platformy**:
   - **Android**: Natywne rozpoznawanie, mów bez limitu
   - **Web**: Chrome Web API, zezwól na mikrofon
3. Tekst zostanie automatycznie dodany do notatki

### 📸 OCR (tekst z obrazów)
1. W edytorze kliknij przycisk "OCR"
2. Wybierz obraz z dysku
3. Poczekaj na przetworzenie
4. Skopiuj rozpoznany tekst

### 📁 Organizacja folderów
- **Nowy folder**: FAB z ikoną folderu
- **Nawigacja**: Kliknij folder aby wejść do środka
- **Powrót**: Strzałka w górę w AppBar
- **Menu kontekstowe**: 3 kropki przy folderze/notatce

### 👥 Współdzielenie notatek
1. Otwórz menu notatki (3 kropki)
2. "Dodaj współtwórcę"
3. Wyszukaj użytkownika po email lub wybierz z listy
4. Współtwórca może edytować notatkę

### 🗑️ Kosz
- **Usuwanie**: Notatki/foldery trafiają do kosza
- **Lokalizacja**: Specjalny folder "Kosz" w głównym widoku
- **Auto-usuwanie**: Po 30 dniach automatyczne usunięcie
- **Przywracanie**: Dostępne w koszu

## 📂 Struktura projektu

```
lib/
├── models/
│   ├── User.dart              # Model użytkownika
│   ├── Note.dart              # Model notatki
│   ├── Folder.dart            # Model folderu
│   └── Collaborator.dart      # Model współtwórcy
├── screens/
│   ├── login/                 # Ekrany logowania
│   │   ├── auth_page.dart
│   │   ├── forgot_screen.dart
│   │   └── reset_screen.dart
│   ├── home/                  # Ekrany główne
│   │   ├── home_screen.dart
│   │   ├── new_note.dart
│   │   ├── ocr_page.dart
│   │   ├── shared_notes.dart
│   │   └── deleted_notes.dart
│   └── speech_recognition_screen.dart
├── services/
│   ├── auth_service.dart      # Firebase Auth
│   ├── android_speech_service.dart    # Android Speech
│   ├── chrome_speech_service.dart     # Web Speech API
│   └── ocr/                   # OCR services
├── utils/                     # Narzędzia pomocnicze
├── widgets/                   # Komponenty UI
└── main.dart                  # Punkt wejścia

# Pozostałe pliki (nieużywane w obecnej wersji)
├── speech_recognizer.py       # Desktop speech (w planach)
└── ocr.py                     # Desktop OCR (w planach)
```

## 🌐 Architektura rozpoznawania mowy

### Android - Native API
```kotlin
// MainActivity.kt implementuje MethodChannel
SpeechRecognizer + RecognitionListener
↓
AndroidSpeechService.dart
↓
speech_recognition_screen.dart
```

### Web - JavaScript API
```javascript
// Chrome Web Speech API
window.SpeechRecognition
↓
ChromeSpeechService.dart (dart:js)
↓
speech_recognition_screen.dart
```

## 🔧 Konfiguracja środowisk

### Firebase Console
- Authentication: Email/Password
- Realtime Database: Europe West 1
- Security Rules: Podstawowe reguły uwierzytelniania

### Web Permissions
```html
<!-- index.html -->
<meta name="permissions-policy" content="microphone=*">
```

### Android Permissions
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

## 📄 API i Integracje

### Firebase Realtime Database
```
/Users/{uid}/              # Dane użytkowników
/Note/{noteId}/           # Notatki
/Folder/{folderId}/       # Foldery
/Collaborators/{collabId}/ # Współtwórcy
```

### Google Speech API
- **Języki**: pl-PL, en-US, de-DE, fr-FR, es-ES
- **Format**: 16kHz, mono
- **Limit**: Zależny od platformy

## 🚧 Znane ograniczenia

1. **Desktop**: Kompletnie nieobsługiwany z powodu problemów z Firebase
2. **iOS**: Nie implementowane (brak iOS-specific speech service)  
3. **Firefox/Safari**: Ograniczone wsparcie Web Speech API
4. **Offline**: Tylko podstawowe funkcje (wymaga internetu dla speech/sync)

## 📞 Autorzy

- **Bartosz Bazan**
- **Paweł Gaj** 
- **Aleksandra Nizio**
- **Jakub Różycki**
- **Jakub Haberek**
- **Mateusz Sarwa**

## 📄 Licencja

Projekt edukacyjny - użycie zgodnie z wytycznymi uczelni.

---

## 🔄 Historia wersji

### v1.0.0 (Aktualna)
- ✅ Android & Web speech recognition
- ✅ OCR implementation (Android/Web)
- ✅ Firebase integration
- ✅ Folder organization
- ✅ Collaboration system
- ✅ Trash/recovery system

### Planowane funkcje
- [ ] Desktop platform support (Firebase compatibility)
- [ ] iOS implementation
- [ ] Offline mode improvements
- [ ] Advanced text formatting
- [ ] Export to PDF
- [ ] Dark theme
- [ ] Real-time collaboration

---

> 💡 **Tip**: Aplikacja działa najlepiej na Android (natywne API) lub Chrome (Web Speech API). Desktop obecnie nieobsługiwany.