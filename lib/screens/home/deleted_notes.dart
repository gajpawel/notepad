import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '/services/auth_service.dart';
import '/models/Note.dart';
import 'package:intl/intl.dart';

class DeletedNotesPage extends StatefulWidget {
  const DeletedNotesPage({super.key});

  @override
  State<DeletedNotesPage> createState() => _DeletedNotesPageState();
}

class _DeletedNotesPageState extends State<DeletedNotesPage> {
  final _db = FirebaseDatabase.instance.ref();
  String? _login;
  List<Note> _deletedNotes = [];

  @override
  void initState() {
    super.initState();
    _loadDeletedNotes();
  }

  Future<void> _loadDeletedNotes() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return;

    final userLogin = user.Login;
    setState(() {
      _login = userLogin;
    });

    final notesSnap = await _db.child('Note').get();

    Set<String> deletedNoteIds = {};

    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    if (notesSnap.exists && notesSnap.value is Map) {
      final data = notesSnap.value as Map;

      for (var entry in data.entries) {
        final key = entry.key;
        final item = entry.value;

        if (item is Map &&
            item['OwnerId'] == userLogin &&
            item['Status'] == false) {

          final modDateStr = item['ModificationDate'] as String?;
          if (modDateStr != null && modDateStr.isNotEmpty) {
            try {
              final modDate = formatter.parse(modDateStr);
              final difference = now.difference(modDate).inDays;

              if (difference > 30) {
                await _db.child('Note').child(key).remove();
                continue; // Pomijamy dodanie ID do listy, bo została usunięta
              }
            } catch (e) {
              print('Nie udało się sparsować daty: $modDateStr - $e');
            }
          }

          deletedNoteIds.add(item['Id'].toString());
        }
      }
    }


    List<Note> deletedNotes = [];

    // Pobierz odpowiadające notatki
    if (notesSnap.exists && notesSnap.value is Map) {
      final data = notesSnap.value as Map;
      for (var item in data.values) {
        if (item is Map) {
          final note = Note.fromJson(Map<String, dynamic>.from(item));
          if (deletedNoteIds.contains(note.Id.toString())) {
            deletedNotes.add(note);
          }
        }
      }
    }

    setState(() {
      _deletedNotes = deletedNotes;
    });
  }

  void _binActions(int id) async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return;

    final userLogin = user.Login;

    final notesSnap = await _db.child('Note').get();

    if (notesSnap.exists && notesSnap.value is Map) {
      final data = notesSnap.value as Map;

      String? noteKey;
      Map? noteData;

      for (var entry in data.entries) {
        final item = entry.value;
        if (item is Map &&
            item['OwnerId'] == userLogin &&
            item['Id'] == id &&
            item['Status'] == false) {
          noteKey = entry.key;
          noteData = item;
          break;
        }
      }

      if (noteKey == null || noteData == null) return;

      final noteName = noteData['Name'] ?? 'Bez nazwy';

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Wybierz akcję dla notatki "$noteName"'),
          actions: [
            TextButton(
              child: const Text('Anuluj'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Usuń trwale', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _db.child('Note').child(noteKey!).remove();
                _loadDeletedNotes(); // odśwież widok
              },
            ),
            TextButton(
              child: const Text('Przywróć'),
              onPressed: () async {
                final now = DateTime.now();
                final formatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

                Navigator.of(context).pop();
                await _db.child('Note').child(noteKey!).update({
                  'Status': true,
                  'ModificationDate': formatted,
                });
                _loadDeletedNotes(); // odśwież widok
              },
            ),
          ],
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📂 Usunięte notatki"),
      ),
      body: _deletedNotes.isEmpty
          ? const Center(child: Text("Kosz jest pusty"))
          : ListView.builder(
        itemCount: _deletedNotes.length,
        itemBuilder: (context, index) {
          final note = _deletedNotes[index];
          return ListTile(
            leading: const Icon(Icons.note_alt_outlined),
            title: Text(note.Name),
            subtitle: Text("Data usunięcia: ${note.ModificationDate}"),
            onTap: () {
              _binActions(note.Id);
            },
          );
        },
      ),
    );
  }
}
