import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'ocr_page.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill/quill_delta.dart';

import '/models/note.dart';

class NewNote extends StatefulWidget {
  final int? noteId;

  const NewNote({super.key, required this.noteId});

  @override
  State<NewNote> createState() => _NewNoteState();
}

class _NewNoteState extends State<NewNote> {
  final TextEditingController _textController = TextEditingController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  late quill.QuillController _quillController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  Note? _note;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _quillController = quill.QuillController(
      document: quill.Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );

    _loadNote();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNote() async {
    try {
      final snapshot = await _dbRef.child('Note').get();

      if (snapshot.exists && snapshot.value is Map) {
        final notes = snapshot.value as Map;

        for (var entry in notes.entries) {
          final noteData = Map<String, dynamic>.from(entry.value);
          if (noteData['Id'] == widget.noteId) {
            final note = Note.fromJson(noteData);

            Delta delta;

            if (note.Content.isNotEmpty) {
              try {
                delta = Delta.fromJson(jsonDecode(note.Content) as List);
              } catch (e) {
                delta = Delta()
                  ..insert('${note.Content}\n');
              }
            } else {
              delta = Delta()
                ..insert('\n');
            }

            setState(() {
              _note = note;
              _quillController = quill.QuillController(
                document: quill.Document.fromDelta(delta),
                selection: const TextSelection.collapsed(offset: 0),
              );
              _isLoading = false;
            });
            return;
          }
        }
      }

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie znaleziono notatki')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd ładowania notatki: $e')),
      );
    }
  }

  Future<void> _saveNote() async {
    if (_note == null) return;

    final now = DateTime.now();

    try {
      final snapshot = await _dbRef.child('Note').get();

      if (snapshot.exists && snapshot.value is Map) {
        final notes = snapshot.value as Map;

        for (var entry in notes.entries) {
          final noteData = Map<String, dynamic>.from(entry.value);
          if (noteData['Id'] == _note!.Id) {
            final contentJson =
            jsonEncode(_quillController.document.toDelta().toJson());

            final updatedNote = Note(
              Id: _note!.Id,
              Name: _note!.Name,
              OwnerId: _note!.OwnerId,
              FolderId: _note!.FolderId,
              CreationDate: _note!.CreationDate,
              ModificationDate: now,
              Content: contentJson,
              Status: _note!.Status,
            );

            await _dbRef.child('Note').child(entry.key).set(
                updatedNote.toJson());

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notatka została zapisana')),
            );
            Navigator.pop(context);
            return;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie znaleziono notatki do aktualizacji')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd podczas zapisu: $e')),
      );
    }
  }

  Future<void> _openOCRPage() async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const OCRPage()),
      );
    }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notatka'),
        // usuń actions z AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            quill.QuillSimpleToolbar(
              controller: _quillController,
              config: const quill.QuillSimpleToolbarConfig(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.all(8),
                child: quill.QuillEditor.basic(
                  controller: _quillController,
                  config: const quill.QuillEditorConfig(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _saveNote,
                  icon: const Icon(Icons.save),
                  label: const Text('Zapisz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // kolor tła
                    foregroundColor: Colors.white, // kolor tekstu i ikony
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _openOCRPage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('OCR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


