import json
import sys
import os
from PIL import Image

def check_dependencies():
    """Sprawdź czy wszystkie wymagane biblioteki są zainstalowane"""
    missing = []
    
    try:
        import easyocr
    except ImportError:
        missing.append("easyocr")
    
    try:
        import torch
    except ImportError:
        missing.append("torch")
    
    try:
        import cv2
    except ImportError:
        missing.append("opencv-python")
    
    if missing:
        error_msg = f"Brakujące biblioteki: {', '.join(missing)}. Zainstaluj używając: pip install {' '.join(missing)}"
        return False, error_msg
    
    return True, ""

def process_image(image_path):
    """Przetwórz obraz używając EasyOCR"""
    
    if not os.path.exists(image_path):
        raise FileNotFoundError(f"Nie można znaleźć pliku: {image_path}")
    
    try:
        with Image.open(image_path) as img:
            img.verify()
    except Exception as e:
        raise ValueError(f"Nieprawidłowy plik obrazu: {str(e)}")
    
    import easyocr
    
    try:

        print("Inicjalizacja EasyOCR...", file=sys.stderr)
        reader = easyocr.Reader(['pl', 'en'], gpu=False, verbose=False)
        print("EasyOCR zainicjalizowany pomyślnie", file=sys.stderr)
        
        print(f"Przetwarzanie obrazu: {image_path}", file=sys.stderr)
        results = reader.readtext(image_path)
        print(f"Znaleziono {len(results)} fragmentów tekstu", file=sys.stderr)
        
        output = []
        for detection in results:
            bbox, text, confidence = detection
            if text.strip():  
                output.append({
                    'text': text.strip(),
                    'confidence': float(confidence),
                    'bbox': [[float(x), float(y)] for x, y in bbox]  
                })
        
        return output
        
    except Exception as e:
        print(f"Błąd podczas przetwarzania EasyOCR: {str(e)}", file=sys.stderr)
        raise

def main():
    try:

        if len(sys.argv) != 2:
            result = {'error': 'Użycie: python ocr.py <ścieżka_do_obrazu>'}
            print(json.dumps(result, ensure_ascii=False))
            sys.exit(1)
        
        image_path = sys.argv[1]
        print(f"Otrzymana ścieżka: {image_path}", file=sys.stderr)
        

        deps_ok, deps_error = check_dependencies()
        if not deps_ok:
            result = {'error': deps_error}
            print(json.dumps(result, ensure_ascii=False))
            sys.exit(1)
        
        results = process_image(image_path)
        
        output = {'results': results, 'status': 'success'}
        print(json.dumps(output, ensure_ascii=False))
        
    except FileNotFoundError as e:
        result = {'error': f'Plik nie znaleziony: {str(e)}'}
        print(json.dumps(result, ensure_ascii=False))
        sys.exit(1)
        
    except ValueError as e:
        result = {'error': f'Błąd walidacji: {str(e)}'}
        print(json.dumps(result, ensure_ascii=False))
        sys.exit(1)
        
    except ImportError as e:
        result = {'error': f'Błąd importu: {str(e)}. Sprawdź czy wszystkie biblioteki są zainstalowane.'}
        print(json.dumps(result, ensure_ascii=False))
        sys.exit(1)
        
    except Exception as e:
        result = {'error': f'Nieoczekiwany błąd: {str(e)}'}
        print(json.dumps(result, ensure_ascii=False))
        sys.exit(1)

if __name__ == "__main__":
    main()