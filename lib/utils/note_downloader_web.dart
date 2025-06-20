// Only compiled on web
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/cupertino.dart';

import '../models/Note.dart';

void downloadNote(Note note, BuildContext context) {
  final bytes = utf8.encode(note.Content);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "${note.Name}.txt")
    ..click();
  html.Url.revokeObjectUrl(url);
}
