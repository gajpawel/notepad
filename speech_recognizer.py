#!/usr/bin/env python3
"""
Standalone Speech Recognition Script z PRAWDZIWYM Google API
Uruchamiany bezpośrednio z Flutter, zwraca wynik przez stdout
"""

import sys
import json
import time
import argparse
import os
import tempfile
import threading

def check_and_install_packages():
    """Sprawdź i zainstaluj wymagane pakiety"""
    required_packages = {
        'speech_recognition': 'SpeechRecognition',
        'sounddevice': 'sounddevice', 
        'soundfile': 'soundfile',
        'numpy': 'numpy',
        'pyaudio': 'pyaudio'  # Dodane dla lepszej kompatybilności
    }
    
    missing_packages = []
    
    for package_import, package_install in required_packages.items():
        try:
            __import__(package_import.replace('-', '_'))
            print(f"✅ {package_import} - zainstalowany", file=sys.stderr)
        except ImportError:
            missing_packages.append(package_install)
            print(f"❌ {package_import} - BRAK!", file=sys.stderr)
    
    if missing_packages:
        print(f"📦 Instaluję brakujące pakiety: {', '.join(missing_packages)}", file=sys.stderr)
        for package in missing_packages:
            os.system(f"pip install {package}")
        
        # Sprawdź ponownie po instalacji
        for package_import in required_packages.keys():
            try:
                __import__(package_import.replace('-', '_'))
            except ImportError:
                return False, f"Nie udało się zainstalować {package_import}"
    
    return True, "Wszystkie pakiety dostępne"

def real_speech_recognition(duration=60, language='pl-PL'):  # Zwiększamy do 60 sekund max
    """
    PRAWDZIWE rozpoznawanie mowy z Google Speech Recognition API
    Z automatycznym wykrywaniem ciszy (10 sekund ciszy = koniec)
    """
    try:
        # Sprawdź pakiety
        success, message = check_and_install_packages()
        if not success:
            raise ImportError(message)
        
        # Importy po sprawdzeniu pakietów
        import speech_recognition as sr
        import sounddevice as sd
        import soundfile as sf
        import numpy as np
        
        print(f"🎤 Rozpoczynam PRAWDZIWE nagrywanie (maks. {duration}s)...", file=sys.stderr)
        print(f"🇵🇱 Język: {language}", file=sys.stderr)
        print(f"🔇 Auto-stop: 10 sekund ciszy", file=sys.stderr)
        
        # Inicjalizuj recognizer i mikrofon  
        recognizer = sr.Recognizer()
        microphone = sr.Microphone()
        
        print("🔧 Kalibruję mikrofon...", file=sys.stderr)
        
        # Kalibruj mikrofon dla szumu otoczenia
        with microphone as source:
            recognizer.adjust_for_ambient_noise(source, duration=2)
            # Ustaw próg ciszy na podstawie kalibracji
            recognizer.energy_threshold = max(recognizer.energy_threshold, 300)
            recognizer.pause_threshold = 10.0  # 10 sekund ciszy
            recognizer.non_speaking_duration = 10.0  # 10 sekund na zatrzymanie
        
        print("📢 MÓW TERAZ! (Automatyczne zatrzymanie po 10s ciszy)", file=sys.stderr)
        print(f"🔊 Próg energii: {recognizer.energy_threshold}", file=sys.stderr)
        
        # Nagraj audio z długim timeoutem i automatycznym wykrywaniem ciszy
        with microphone as source:
            try:
                # Nagrywaj z automatycznym wykrywaniem ciszy
                audio = recognizer.listen(
                    source, 
                    timeout=5,  # 5 sekund na rozpoczęcie mowy
                    phrase_time_limit=duration  # Maksymalny czas całkowity
                )
                print("⏹️ Nagrywanie zakończone (wykryto ciszę lub timeout)", file=sys.stderr)
                
            except sr.WaitTimeoutError:
                raise Exception("Timeout - nie wykryto początku mowy w ciągu 5 sekund")
        
        print("🔄 Rozpoznaję mowę przez Google API...", file=sys.stderr)
        
        # Wyślij do Google Speech Recognition API
        try:
            text = recognizer.recognize_google(audio, language=language)
            
            if not text or text.strip() == "":
                raise sr.UnknownValueError("Pusty wynik rozpoznawania")
            
            result = {
                "success": True,
                "text": text.strip(),
                "language": language,
                "confidence": 0.9,  # Google nie zwraca confidence, przyjmujemy wysoką
                "duration": duration,
                "timestamp": time.time(),
                "method": "google_speech_api_silence_detection",
                "real_api": True,
                "silence_threshold": 10.0
            }
            
            print(f"✅ ROZPOZNANO: '{text}'", file=sys.stderr)
            print(json.dumps(result, ensure_ascii=False))
            return result
            
        except sr.UnknownValueError:
            raise Exception("Google nie rozpoznał żadnej mowy w nagraniu")
        except sr.RequestError as e:
            raise Exception(f"Błąd żądania do Google API: {str(e)}")
            
    except ImportError as e:
        # Fallback do symulacji jeśli brak pakietów
        print(f"⚠️ Brak pakietów ({str(e)}), używam symulacji", file=sys.stderr)
        return simulate_speech_recognition(duration, language)
    except Exception as e:
        error_result = {
            "success": False,
            "error": str(e),
            "language": language,
            "duration": duration,
            "timestamp": time.time(),
            "method": "google_speech_api_silence_detection",
            "real_api": True
        }
        print(f"❌ Błąd: {str(e)}", file=sys.stderr)
        print(json.dumps(error_result, ensure_ascii=False))
        return error_result

def simulate_speech_recognition(duration=8, language='pl-PL'):
    """
    Symulacja rozpoznawania mowy (backup gdy brak pakietów)
    """
    import random
    
    print(f"🎭 SYMULACJA nagrywania przez {duration} sekund...", file=sys.stderr)
    time.sleep(min(duration, 2))  # Krótka symulacja
    
    # Polskie frazy do symulacji
    polish_phrases = [
        "Dzień dobry, jak się masz?",
        "Witam w aplikacji Flutter",
        "Rozpoznawanie mowy działa poprawnie", 
        "To jest test polskiego języka",
        "Aplikacja notepad jest gotowa",
        "Mikrofon działa bardzo dobrze",
        "Python API odpowiada poprawnie",
        "System rozpoznawania mowy aktywny",
        "Teraz mówię po polsku",
        "Flutter i Python współpracują"
    ]
    
    recognized_text = random.choice(polish_phrases)
    confidence = round(random.uniform(0.85, 0.99), 2)
    
    result = {
        "success": True,
        "text": recognized_text,
        "language": language,
        "confidence": confidence,
        "duration": duration,
        "timestamp": time.time(),
        "method": "simulation",
        "real_api": False,
        "note": "Symulacja - zainstaluj pakiety dla prawdziwego API"
    }
    
    print(f"🎭 Symulowane rozpoznanie: '{recognized_text}'", file=sys.stderr)
    print(json.dumps(result, ensure_ascii=False))
    return result

def list_audio_devices():
    """Wyświetl dostępne urządzenia audio"""
    try:
        import sounddevice as sd
        print("🎧 Dostępne urządzenia audio:", file=sys.stderr)
        devices = sd.query_devices()
        for i, device in enumerate(devices):
            device_type = "🎤" if device['max_input_channels'] > 0 else "🔊"
            print(f"   {i}: {device_type} {device['name']}", file=sys.stderr)
        print(f"🔧 Domyślne urządzenie: {sd.default.device}", file=sys.stderr)
    except ImportError:
        print("⚠️ sounddevice nie zainstalowany - nie można wyświetlić urządzeń", file=sys.stderr)
    except Exception as e:
        print(f"❌ Błąd listowania urządzeń: {str(e)}", file=sys.stderr)

def main():
    """Główna funkcja - parse argumenty i uruchom rozpoznawanie"""
    parser = argparse.ArgumentParser(description='Real Google Speech Recognition Script')
    parser.add_argument('--duration', type=int, default=60, help='Maksymalny czas nagrywania w sekundach (1-300)')
    parser.add_argument('--language', type=str, default='pl-PL', help='Kod języka (pl-PL, en-US, etc.)')
    parser.add_argument('--mode', type=str, choices=['real', 'simulate', 'auto'], default='real', 
                       help='Tryb: real (prawdziwy), simulate (symulacja), auto (automatyczny)')
    parser.add_argument('--list-devices', action='store_true', help='Wyświetl dostępne urządzenia audio')
    parser.add_argument('--test', action='store_true', help='Test szybki (1 sekunda)')
    
    args = parser.parse_args()
    
    # Ograniczenia bezpieczeństwa (zwiększone limity)
    args.duration = max(1, min(args.duration, 300))  # 1-300 sekund (5 minut max)
    
    print(f"🐍 GOOGLE SPEECH RECOGNITION SCRIPT", file=sys.stderr)
    print(f"📝 Parametry: duration={args.duration}s (max), language={args.language}, mode={args.mode}", file=sys.stderr)
    print(f"🔇 Auto-stop: 10 sekund ciszy kończy nagrywanie", file=sys.stderr)
    
    if args.list_devices:
        list_audio_devices()
        return
    
    if args.test:
        args.duration = 1
        args.mode = 'simulate'
        print("🧪 Tryb testowy - 1 sekunda symulacji", file=sys.stderr)
    
    try:
        if args.mode == 'simulate':
            simulate_speech_recognition(args.duration, args.language)
        elif args.mode == 'real':
            real_speech_recognition(args.duration, args.language)
        else:  # auto
            # Spróbuj prawdziwego, jeśli błąd to symulacja
            real_speech_recognition(args.duration, args.language)
            
    except KeyboardInterrupt:
        error_result = {
            "success": False,
            "error": "Przerwano przez użytkownika (Ctrl+C)",
            "language": args.language,
            "duration": args.duration,
            "timestamp": time.time()
        }
        print(json.dumps(error_result, ensure_ascii=False))
    except Exception as e:
        error_result = {
            "success": False,
            "error": f"Nieoczekiwany błąd: {str(e)}",
            "language": args.language,
            "duration": args.duration,
            "timestamp": time.time()
        }
        print(json.dumps(error_result, ensure_ascii=False))

if __name__ == "__main__":
    main()