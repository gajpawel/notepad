package com.example.notepad

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore

class MainActivity: FlutterActivity() {
    private val CHANNEL = "flutter_speech_recognition"
    private val MICROPHONE_PERMISSION_CODE = 200
    private val CHANNEL_FILES = "com.example.notepad/files"
    private var speechRecognizer: SpeechRecognizer? = null
    private var methodChannel: MethodChannel? = null
    private var isListening = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "isRecognitionAvailable" -> {
                    result.success(SpeechRecognizer.isRecognitionAvailable(this))
                }
                "checkMicrophonePermission" -> {
                    val hasPermission = ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECORD_AUDIO
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(hasPermission)
                }
                "requestMicrophonePermission" -> {
                    requestMicrophonePermission()
                    result.success(true) // Async, rzeczywisty wynik w callback
                }
                "startListening" -> {
                    val language = call.argument<String>("language") ?: "pl-PL"
                    val partialResults = call.argument<Boolean>("partialResults") ?: true
                    val continuous = call.argument<Boolean>("continuous") ?: true
                    val maxResults = call.argument<Int>("maxResults") ?: 1
                    val timeoutMillis = call.argument<Int>("timeoutMillis")

                    startListening(language, partialResults, continuous, maxResults, timeoutMillis)
                    result.success(true)
                }
                "stopListening" -> {
                    stopListening()
                    result.success(true)
                }
                "cancelListening" -> {
                    cancelListening()
                    result.success(true)
                }
                "getAvailableLanguages" -> {
                    // Podstawowe języki - Android może mieć więcej
                    val languages = listOf(
                        "pl-PL", "en-US", "en-GB", "de-DE", "fr-FR",
                        "es-ES", "it-IT", "ru-RU", "ja-JP", "ko-KR"
                    )
                    result.success(languages)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.example.notepad/files")
            .setMethodCallHandler { call, result ->
                if (call.method == "saveToDownloads") {
                    val fileName = call.argument<String>("fileName")
                    val content = call.argument<String>("content")
                    if (fileName != null && content != null) {
                        val success = saveTextToDownloads(fileName, content)
                        result.success(success)
                    } else {
                        result.success(false)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
    
    private fun requestMicrophonePermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            MICROPHONE_PERMISSION_CODE
        )
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == MICROPHONE_PERMISSION_CODE) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            
            // Powiadom Flutter o wyniku
            methodChannel?.invokeMethod("onPermissionResult", mapOf("granted" to granted))
        }
    }
    
    private fun startListening(
        language: String,
        partialResults: Boolean,
        continuous: Boolean,
        maxResults: Int,
        timeoutMillis: Int?
    ) {
        if (isListening) {
            return // Już nasłuchuje
        }
        
        // Sprawdź uprawnienia
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) 
            != PackageManager.PERMISSION_GRANTED) {
            methodChannel?.invokeMethod("onSpeechError", mapOf("error" to "ERROR_INSUFFICIENT_PERMISSIONS"))
            return
        }
        
        // Utwórz SpeechRecognizer
        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        
        if (speechRecognizer == null) {
            methodChannel?.invokeMethod("onSpeechError", mapOf("error" to "ERROR_CLIENT"))
            return
        }
        
        // Ustaw listener
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                println("🎤 Android Speech: Gotowy do nasłuchiwania")
                isListening = true
                methodChannel?.invokeMethod("onListeningStarted", null)
            }
            
            override fun onBeginningOfSpeech() {
                println("🗣️ Android Speech: Wykryto mowę")
            }
            
            override fun onRmsChanged(rmsdB: Float) {
                // Poziom głośności - można dodać wizualizację
            }
            
            override fun onBufferReceived(buffer: ByteArray?) {
                // Surowe dane audio - zwykle nie używane
            }
            
            override fun onEndOfSpeech() {
                println("⏹️ Android Speech: Koniec mowy")
            }
            
            override fun onError(error: Int) {
                println("❌ Android Speech błąd: $error")
                isListening = false
                
                val errorMessage = when (error) {
                    SpeechRecognizer.ERROR_AUDIO -> "ERROR_AUDIO"
                    SpeechRecognizer.ERROR_CLIENT -> "ERROR_CLIENT"
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "ERROR_INSUFFICIENT_PERMISSIONS"
                    SpeechRecognizer.ERROR_NETWORK -> "ERROR_NETWORK"
                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "ERROR_NETWORK_TIMEOUT"
                    SpeechRecognizer.ERROR_NO_MATCH -> "ERROR_NO_MATCH"
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "ERROR_RECOGNIZER_BUSY"
                    SpeechRecognizer.ERROR_SERVER -> "ERROR_SERVER"
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "ERROR_SPEECH_TIMEOUT"
                    else -> "ERROR_UNKNOWN"
                }
                
                methodChannel?.invokeMethod("onSpeechError", mapOf("error" to errorMessage))
            }
            
            override fun onResults(results: Bundle?) {
                println("✅ Android Speech: Otrzymano wyniki")
                isListening = false
                
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (!matches.isNullOrEmpty()) {
                    val bestMatch = matches[0]
                    println("📝 Najlepszy wynik: $bestMatch")
                    
                    methodChannel?.invokeMethod("onSpeechResult", mapOf(
                        "text" to bestMatch,
                        "isFinal" to true
                    ))
                }
                
                methodChannel?.invokeMethod("onListeningStopped", null)
            }
            
            override fun onPartialResults(partialResults: Bundle?) {
                if (partialResults != null) {
                    val matches = partialResults.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                    if (!matches.isNullOrEmpty()) {
                        val partialText = matches[0]
                        println("📝 Wynik częściowy: $partialText")
                        
                        methodChannel?.invokeMethod("onSpeechResult", mapOf(
                            "text" to partialText,
                            "isFinal" to false
                        ))
                    }
                }
            }
            
            override fun onEvent(eventType: Int, params: Bundle?) {
                // Dodatkowe wydarzenia - opcjonalne
            }
        })
        
        // Przygotuj Intent dla rozpoznawania
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, language)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, partialResults)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, maxResults)
            
            // Dodaj timeout jeśli podany
            timeoutMillis?.let {
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, it)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, it)
            }
        }
        
        // Rozpocznij rozpoznawanie
        try {
            speechRecognizer?.startListening(intent)
            println("🎤 Android Speech: Rozpoczynam nasłuchiwanie ($language)")
        } catch (e: Exception) {
            println("❌ Błąd startListening: ${e.message}")
            methodChannel?.invokeMethod("onSpeechError", mapOf("error" to "ERROR_CLIENT"))
        }
    }
    
    private fun stopListening() {
        if (isListening && speechRecognizer != null) {
            speechRecognizer?.stopListening()
            println("⏹️ Android Speech: Stop listening")
        }
    }
    
    private fun cancelListening() {
        if (speechRecognizer != null) {
            speechRecognizer?.cancel()
            speechRecognizer?.destroy()
            speechRecognizer = null
            isListening = false
            println("❌ Android Speech: Cancel listening")
            
            methodChannel?.invokeMethod("onListeningStopped", null)
        }
    }

    private fun saveTextToDownloads(fileName: String, content: String): Boolean {
        return try {
            val resolver = contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, "text/plain")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS)
                }
            }

            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, contentValues)
                ?: return false

            val outputStream = resolver.openOutputStream(uri)
            outputStream?.write(content.toByteArray())
            outputStream?.flush()
            outputStream?.close()

            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        cancelListening()
    }
}