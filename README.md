# Noteable 📝

Nowoczesny notatnik napisany we Flutterze z zaawansowanymi funkcjami rozpoznawania tekstu.

## ✨ Funkcje

- 📱 **Wieloplatformowość** - działa na Androidzie i w przeglądarce
- 🎤 **Rozpoznawanie mowy** - twórz notatki głosem w czasie rzeczywistym
- 📸 **OCR ze zdjęć** - wyodrębnij tekst z obrazów i zdjęć
- 💾 **Lokalne przechowywanie** - wszystkie notatki zapisywane bezpiecznie na urządzeniu
- 🔍 **Wyszukiwanie** - szybko znajdź swoje notatki
- 🎨 **Nowoczesny interfejs** - czytelny i intuicyjny design

## 🚀 Technologie

- **Flutter** - framework główny
- **Speech-to-Text** - rozpoznawanie mowy
- **OCR (Optical Character Recognition)** - rozpoznawanie tekstu z obrazów
- **SQLite** - lokalna baza danych
- **Provider/Bloc** - zarządzanie stanem

## 📱 Platformy

- ✅ Android (natywna aplikacja)
- ✅ Web (Progressive Web App)
- 🔄 iOS (planowane)

## 🛠️ Instalacja

### Wymagania
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Android Studio / VS Code
- Emulator Androida lub fizyczne urządzenie

### Kroki instalacji

1. **Sklonuj repozytorium**
```bash
git clone https://github.com/twoje-repo/noteable.git
cd noteable
```

2. **Zainstaluj zależności**
```bash
flutter pub get
```

3. **Uruchom na Androidzie**
```bash
flutter run
```

4. **Uruchom w przeglądarce**
```bash
flutter run -d chrome
```

## 🎯 Jak używać

### Tworzenie notatek głosem
1. Otwórz aplikację
2. Dotknij ikonę mikrofonu 🎤
3. Mów wyraźnie - tekst pojawi się automatycznie
4. Dotknij "Stop" aby zakończyć nagrywanie

### Rozpoznawanie tekstu ze zdjęć
1. Dotknij ikonę aparatu 📸
2. Zrób zdjęcie tekstu lub wybierz z galerii
3. Aplikacja automatycznie wyodrębni tekst
4. Edytuj i zapisz notatkę

### Zarządzanie notatkami
- **Dodaj nową** - przycisk "+" w prawym dolnym rogu
- **Edytuj** - dotknij istniejącą notatkę
- **Usuń** - przesuń palcem w lewo na notatce
- **Szukaj** - użyj paska wyszukiwania u góry

## 🔧 Konfiguracja

### Uprawnienia (Android)
Aplikacja wymaga następujących uprawnień:
- `RECORD_AUDIO` - dla rozpoznawania mowy
- `CAMERA` - dla robienia zdjęć
- `READ_EXTERNAL_STORAGE` - dla dostępu do galerii

### Ustawienia przeglądarki
Dla pełnej funkcjonalności w przeglądarce:
- Zezwól na dostęp do mikrofonu
- Zezwól na dostęp do kamery
- Używaj HTTPS dla najlepszej kompatybilności

## 📂 Struktura projektu

```
lib/
├── models/          # Modele danych
├── screens/         # Ekrany aplikacji
├── widgets/         # Komponenty UI
├── services/        # Usługi (OCR, Speech-to-Text)
├── providers/       # Zarządzanie stanem
└── utils/           # Narzędzia pomocnicze
```

## 📄 Licencja

Ten projekt jest licencjonowany na licencji MIT - szczegóły w pliku [LICENSE](LICENSE).

## 📞 Autorzy

- **Autorzy**: [Bartosz Bazan], [Paweł Gaj], [Aleksandra Nizio], [Jakub Różycki], [Mateusz Sarwa]


## 🔄 Plan rozwoju

- [ ] Synchronizacja w chmurze
- [ ] Eksport do PDF
- [ ] Organizacja w foldery
- [ ] Ciemny motyw
- [ ] Aplikacja na iOS
- [ ] Współpraca w czasie rzeczywistym

---

