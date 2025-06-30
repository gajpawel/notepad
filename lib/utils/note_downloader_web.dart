// Only compiled on web
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../models/Note.dart';
import 'package:flutter_quill/quill_delta.dart';

void downloadNote(Note note, BuildContext context) {
  String plainText;

  try {
    final deltaJson = jsonDecode(note.Content);
    final delta = Delta.fromJson(deltaJson as List);
    final doc = quill.Document.fromDelta(delta);
    plainText = doc.toPlainText();
  } catch (e) {
    plainText = note.Content;
  }

  final bytes = utf8.encode(plainText);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "${note.Name}.txt")
    ..click();
  html.Url.revokeObjectUrl(url);
}
