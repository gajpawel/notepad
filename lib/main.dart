import 'package:flutter/material.dart';
import 'screens/login/auth_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';

const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyA7TvPSmjOk3qZirF_u3dXVCt7a0rHTyDs",
  authDomain: "notepaddb-5e65b.firebaseapp.com",
  databaseURL: "https://notepaddb-5e65b-default-rtdb.europe-west1.firebasedatabase.app",
  projectId: "notepaddb-5e65b",
  storageBucket: "notepaddb-5e65b.firebasestorage.app",
  messagingSenderId: "688158558009",
  appId: "1:688158558009:web:c5260066cfbe7469a30ae8",
  measurementId: "G-52CD72846N",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: firebaseOptions,
    );
  } catch (e) {
    print('Błąd inicjalizacji Firebase: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noteable App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pl'),
      ],
      home: const AuthPage(),
    );
  }
}
