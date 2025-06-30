import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import '../models/Note.dart';

Future<void> downloadNote(Note note, BuildContext context) async {
  const platform = MethodChannel('com.example.notepad/files');

  try {
    String plainText;
    try {
      final deltaJson = jsonDecode(note.Content);
      final delta = Delta.fromJson(deltaJson as List);
      final doc = quill.Document.fromDelta(delta);
      plainText = doc.toPlainText();
    } catch (e) {
      plainText = note.Content;
    }

    final result = await platform.invokeMethod('saveToDownloads', {
      'fileName': '${note.Name}.txt',
      'content': plainText,
    });

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notatka zapisana w Downloads')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się zapisać pliku')),
      );
    }
  } on PlatformException catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Błąd zapisu: ${e.message}')),
    );
  }
}