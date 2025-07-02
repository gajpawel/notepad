import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';
import 'package:flutter_quill_to_pdf/flutter_quill_to_pdf.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../models/Note.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';

Future<void> downloadNote(Note note, BuildContext context) async {
  final robotoFont = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Roboto-Regular.ttf')
  );

  try {
    quill.Document doc;
    try {
      final deltaJson = jsonDecode(note.Content);
      final delta = Delta.fromJson(deltaJson as List);
      doc = quill.Document.fromDelta(delta);
    } catch (e) {
      doc = quill.Document()..insert(0, note.Content);
    }

    // Utwórz format strony (np. A4 z marginesem 40)
    final pageFormat = PDFPageFormat.all(
      width: PdfPageFormat.a4.width,
      height: PdfPageFormat.a4.height,
      margin: 40,
    );

    // Utwórz konwerter
    final pdfConverter = PDFConverter(
      document: doc.toDelta(),
      pageFormat: pageFormat,
      textDirection: Directionality.of(context),
      isWeb: kIsWeb,
      documentOptions: DocumentOptions(
        title: note.Name,
        author: 'Notepad App',
        producer: 'Notepad App',
      ),
      themeData: pw.ThemeData.withFont(base: robotoFont),
      fallbacks: [robotoFont],
    );

    final pdfDoc = await pdfConverter.createDocument();

    if (pdfDoc != null) {
      final Uint8List pdfBytes = await pdfDoc.save();

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: '${_safeFileName(note.Name)}.pdf',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się utworzyć dokumentu PDF')),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF wygenerowany')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Błąd generowania PDF: $e')),
    );
  }
}

String _safeFileName(String name) {
  return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}