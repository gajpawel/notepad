import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'ocr_page.dart';

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

  Note? _note;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNote();
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
            setState(() {
              _note = note;
              _textController.text = note.Content;
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

    final updatedContent = _textController.text.trim();
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    try {
      final snapshot = await _dbRef.child('Note').get();

      if (snapshot.exists && snapshot.value is Map) {
        final notes = snapshot.value as Map;

        for (var entry in notes.entries) {
          final noteData = Map<String, dynamic>.from(entry.value);
          if (noteData['Id'] == _note!.Id) {
            final updatedNote = Note(
              Id: _note!.Id,
              Name: _note!.Name,
              OwnerId: _note!.OwnerId,
              FolderId: _note!.FolderId,
              CreationDate: _note!.CreationDate,
              ModificationDate: now,
              Content: updatedContent,
              Status: _note!.Status,
            );

            await _dbRef.child('Note').child(entry.key).set(updatedNote.toJson());

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_note?.Name ?? 'Notatka'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Treść notatki',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
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


