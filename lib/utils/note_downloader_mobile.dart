// Only compiled on mobile (Android/iOS)
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../models/Note.dart';

Future<void> downloadNote(Note note, BuildContext context) async {
  try {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak uprawnień do zapisu pliku')),
      );
      return;
    }

    final directory = await getExternalStorageDirectory();
    if (directory == null) throw Exception("Brak dostępu do katalogu");

    final path = '${directory.path}/${note.Name}.txt';
    final file = File(path);
    await file.writeAsString(note.Content);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notatka zapisana jako plik .txt')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Błąd zapisu: $e')),
    );
  }
}
