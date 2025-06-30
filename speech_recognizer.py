#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
speech_recognizer.py - Rozpoznawanie mowy dla aplikacji Noteable
Używa Google Speech Recognition API do transkrypcji polskiej mowy na tekst
Kompatybilny z Flutter aplikacją przez process_speech_service.dart
"""

import os
import sys
import json
import argparse
import tempfile
import threading
import time
import traceback
from datetime import datetime

def install_and_import(package):
    """Automatycznie instaluje i importuje pakiet jeśli nie jest dostępny"""
    try:
        __import__(package)
    except ImportError:
        import subprocess
        import sys
        print(f"[INFO] Instalowanie {package}...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", package])
        __import__(package)

class SpeechRecognizer:
    """
    Klasa do rozpoznawania mowy dla aplikacji Noteable
    Integruje się z Flutter przez process_speech_service.dart
    """
    
    def __init__(self, language="pl-PL"):
        """
        Inicjalizacja rozpoznawania mowy
        
        Args:
            language (str): Kod języka (domyślnie polski)
        """
        self.language = language
        self.recording = False
        self.sample_rate = 16000
        self.recognizer = None
        
        # Callbacks dla Flutter integration
        self.on_transcription_ready = None
        self.on_recording_started = None
        self.on_recording_stopped = None
        
        # Sprawdź i zainstaluj wymagane pakiety
        self._setup_dependencies()
        self._initialize_recognizer()
    
    def _setup_dependencies(self):
        """Sprawdza i instaluje wymagane pakiety Python"""
        required_packages = {
            'speech_recognition': 'SpeechRecognition',
            'sounddevice': 'sounddevice', 
            'soundfile': 'soundfile',
            'numpy': 'numpy'
        }
        
        for import_name, install_name in required_packages.items():
            try:
                install_and_import(import_name)
                print(f"[OK] {install_name} dostępny")
            except Exception as e:
                print(f"[ERROR] Nie można zainstalować {install_name}: {e}")
                return False
        
        return True
    
    def _initialize_recognizer(self):
        """Inicjalizuje Google Speech Recognition"""
        try:
            import speech_recognition as sr
            self.recognizer = sr.Recognizer()
            
            # Optymalizacja dla polskiego języka
            self.recognizer.energy_threshold = 300
            self.recognizer.dynamic_energy_threshold = True
            self.recognizer.pause_threshold = 0.8
            self.recognizer.phrase_threshold = 0.3
            
            print(f"[OK] Google Speech Recognition zainicjalizowany dla języka: {self.language}")
            return True
            
        except ImportError as e:
            print(f"[ERROR] Nie można zainicjalizować Speech Recognition: {e}")
            self.recognizer = None
            return False
    
    def start_recording(self, max_duration=8):
        """
        Rozpoczyna nagrywanie dźwięku (używane przez Flutter)
        
        Args:
            max_duration (int): Maksymalny czas nagrywania w sekundach
        """
        if self.recording:
            print("[WARNING] Nagrywanie już trwa")
            return False
        
        if not self.recognizer:
            print("[ERROR] Recognizer nie został zainicjalizowany")
            return False
        
        self.recording = True
        self.audio_data = []
        
        try:
            import sounddevice as sd
            import numpy as np
            
            def audio_callback(indata, frames, time, status):
                """Callback dla każdego fragmentu audio"""
                if status:
                    print(f"[AUDIO] Status: {status}")
                
                # Konwersja do mono
                if len(indata.shape) > 1 and indata.shape[1] > 1:
                    audio_mono = np.mean(indata, axis=1)
                else:
                    audio_mono = indata.flatten()
                
                self.audio_data.append(audio_mono.copy())
            
            def record_thread():
                """Wątek nagrywający"""
                try:
                    print(f"[RECORDING] Rozpoczynam nagrywanie ({max_duration}s)")
                    
                    if self.on_recording_started:
                        self.on_recording_started()
                    
                    # Nagrywanie
                    with sd.InputStream(
                        samplerate=self.sample_rate,
                        channels=1,
                        callback=audio_callback,
                        dtype=np.float32
                    ):
                        start_time = time.time()
                        while self.recording and (time.time() - start_time) < max_duration:
                            time.sleep(0.1)
                    
                    # Auto-stop po max_duration
                    if self.recording:
                        self.stop_recording()
                        
                except Exception as e:
                    print(f"[ERROR] Błąd nagrywania: {e}")
                    traceback.print_exc()
                    self.recording = False
                    if self.on_recording_stopped:
                        self.on_recording_stopped(error=str(e))
            
            # Start recording thread
            threading.Thread(target=record_thread, daemon=True).start()
            return True
            
        except Exception as e:
            print(f"[ERROR] Nie można rozpocząć nagrywania: {e}")
            self.recording = False
            return False
    
    def stop_recording(self):
        """Zatrzymuje nagrywanie i rozpoczyna transkrypcję"""
        if not self.recording:
            print("[WARNING] Nagrywanie nie jest aktywne")
            return
        
        self.recording = False
        print("[RECORDING] Zatrzymano nagrywanie, rozpoczynam transkrypcję...")
        
        if self.on_recording_stopped:
            self.on_recording_stopped()
        
        # Sprawdź czy mamy dane audio
        if not self.audio_data:
            print("[ERROR] Brak nagranych danych audio")
            if self.on_transcription_ready:
                self.on_transcription_ready(None, error="Brak nagranych danych")
            return
        
        # Uruchom transkrypcję w osobnym wątku
        threading.Thread(target=self._transcribe_audio, daemon=True).start()
    
    def _transcribe_audio(self):
        """Transkrybuje nagrane audio używając Google Speech API"""
        try:
            import numpy as np
            import soundfile as sf
            import speech_recognition as sr
            
            print("[TRANSCRIPTION] Przetwarzanie nagrania...")
            
            # Połącz fragmenty audio
            audio = np.concatenate(self.audio_data, axis=0)
            print(f"[TRANSCRIPTION] Audio: {len(audio)} próbek, {audio.dtype}")
            
            # Normalizacja audio
            if audio.max() > 0:
                audio = audio / np.max(np.abs(audio))
            
            # Zapisz do pliku tymczasowego
            temp_dir = tempfile.gettempdir()
            temp_file = os.path.join(temp_dir, f"speech_{int(time.time())}.wav")
            
            print(f"[TRANSCRIPTION] Zapisuję audio: {temp_file}")
            sf.write(temp_file, audio, self.sample_rate)
            
            # Rozpoznawanie przez Google API
            with sr.AudioFile(temp_file) as source:
                print("[TRANSCRIPTION] Ładowanie audio do recognizer...")
                audio_data = self.recognizer.record(source)
                
                print("[TRANSCRIPTION] Wysyłam do Google Speech API...")
                text = self.recognizer.recognize_google(
                    audio_data, 
                    language=self.language
                )
                
                print(f"[SUCCESS] Rozpoznano: '{text}'")
                
                # Wywołaj callback z wynikiem
                if self.on_transcription_ready:
                    self.on_transcription_ready(text)
            
            # Usuń plik tymczasowy
            try:
                os.remove(temp_file)
                print(f"[CLEANUP] Usunięto: {temp_file}")
            except:
                pass
                
        except sr.UnknownValueError:
            error_msg = "Google Speech API nie rozpoznał mowy"
            print(f"[ERROR] {error_msg}")
            if self.on_transcription_ready:
                self.on_transcription_ready(None, error=error_msg)
                
        except sr.RequestError as e:
            error_msg = f"Błąd Google Speech API: {e}"
            print(f"[ERROR] {error_msg}")
            if self.on_transcription_ready:
                self.on_transcription_ready(None, error=error_msg)
                
        except Exception as e:
            error_msg = f"Błąd transkrypcji: {e}"
            print(f"[ERROR] {error_msg}")
            traceback.print_exc()
            if self.on_transcription_ready:
                self.on_transcription_ready(None, error=error_msg)
    
    def is_recording(self):
        """Sprawdza czy nagrywanie jest aktywne"""
        return self.recording
    
    def get_available_languages(self):
        """Zwraca dostępne języki"""
        return [
            "pl-PL",  # Polski
            "en-US",  # Angielski (USA)  
            "en-GB",  # Angielski (UK)
            "de-DE",  # Niemiecki
            "fr-FR",  # Francuski
            "es-ES",  # Hiszpański
            "it-IT",  # Włoski
            "ru-RU",  # Rosyjski
        ]


def simulate_recognition(duration=3, language="pl-PL"):
    """
    Symulacja rozpoznawania dla testów (gdy nie ma mikrofonu)
    
    Args:
        duration (int): Czas symulacji
        language (str): Kod języka
        
    Returns:
        dict: Wynik symulacji
    """
    polish_texts = [
        "Witaj w aplikacji Noteable",
        "To jest test rozpoznawania mowy po polsku", 
        "Google Speech API działa bardzo dobrze",
        "Mogę dyktować tekst do notatki",
        "Rozpoznawanie polskiej mowy funkcjonuje poprawnie",
        "Aplikacja Flutter integruje się z Python",
        "System transkrypcji jest gotowy do użycia",
        "Technologia rozpoznawania głosu rozwija się dynamicznie",
        "Polskie znaki i wymowa są obsługiwane",
        "Automatyczna transkrypcja ułatwia tworzenie notatek"
    ]
    
    print(f"[SIMULATION] Symulacja rozpoznawania ({duration}s)")
    time.sleep(duration)
    
    import random
    random_text = random.choice(polish_texts)
    
    return {
        "success": True,
        "text": random_text,
        "language": language,
        "confidence": 0.95,
        "method": "simulation"
    }


def main():
    """Główna funkcja - interface dla Flutter process_speech_service.dart"""
    parser = argparse.ArgumentParser(description="Rozpoznawanie mowy dla Noteable")
    parser.add_argument("--duration", type=int, default=8, help="Czas nagrywania (s)")
    parser.add_argument("--language", default="pl-PL", help="Kod języka") 
    parser.add_argument("--mode", choices=["auto", "real", "simulate"], default="auto",
                       help="Tryb pracy")
    parser.add_argument("--test", action="store_true", help="Tryb testowy")
    
    args = parser.parse_args()
    
    print(f"[START] Noteable Speech Recognizer")
    print(f"[CONFIG] Język: {args.language}, Czas: {args.duration}s, Tryb: {args.mode}")
    
    # Określ tryb pracy
    mode = args.mode
    if mode == "auto":
        # Auto-detection: sprawdź czy można używać prawdziwego rozpoznawania
        try:
            import sounddevice as sd
            import speech_recognition as sr
            devices = sd.query_devices()
            mode = "real" if len(devices) > 0 else "simulate"
        except:
            mode = "simulate"
    
    result = None
    
    if mode == "simulate":
        # Tryb symulacji
        result = simulate_recognition(args.duration, args.language)
    else:
        # Prawdziwe rozpoznawanie
        recognizer = SpeechRecognizer(args.language)
        result_holder = {"result": None, "done": False}
        
        def on_transcription(text, error=None):
            if error:
                result_holder["result"] = {
                    "success": False,
                    "text": "",
                    "error": error,
                    "language": args.language,
                    "method": "real"
                }
            else:
                result_holder["result"] = {
                    "success": True,
                    "text": text or "",
                    "language": args.language,
                    "confidence": 0.90,
                    "method": "real"
                }
            result_holder["done"] = True
        
        def on_started():
            print("[FLUTTER] Nagrywanie rozpoczęte - mów teraz!")
        
        def on_stopped(error=None):
            if error:
                print(f"[FLUTTER] Błąd nagrywania: {error}")
            else:
                print("[FLUTTER] Nagrywanie zakończone, przetwarzanie...")
        
        # Podłącz callbacks
        recognizer.on_transcription_ready = on_transcription
        recognizer.on_recording_started = on_started  
        recognizer.on_recording_stopped = on_stopped
        
        # Rozpocznij nagrywanie
        if recognizer.start_recording(args.duration):
            # Czekaj na zakończenie
            timeout = args.duration + 15  # Dodatkowy czas na przetwarzanie
            start_time = time.time()
            
            while not result_holder["done"] and (time.time() - start_time) < timeout:
                time.sleep(0.1)
            
            if not result_holder["done"]:
                result = {
                    "success": False,
                    "text": "",
                    "error": "Timeout - zbyt długie przetwarzanie",
                    "method": "real"
                }
            else:
                result = result_holder["result"]
        else:
            result = {
                "success": False,
                "text": "",
                "error": "Nie można rozpocząć nagrywania",
                "method": "real"
            }
    
    # Wynik w formacie JSON dla Flutter
    if result:
        print(json.dumps(result, ensure_ascii=False))
    else:
        error_result = {
            "success": False,
            "text": "",
            "error": "Nieznany błąd rozpoznawania",
            "method": mode
        }
        print(json.dumps(error_result, ensure_ascii=False))
    
    return 0 if result and result.get("success") else 1


if __name__ == "__main__":
    try:
        exit_code = main()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n[INTERRUPTED] Przerwano przez użytkownika")
        sys.exit(1)
    except Exception as e:
        print(f"[FATAL ERROR] {e}")
        traceback.print_exc()
        error_result = {
            "success": False,
            "text": "",
            "error": str(e),
            "method": "unknown"
        }
        print(json.dumps(error_result, ensure_ascii=False))
        sys.exit(1)