import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '/services/auth_service.dart';
import '/models/Note.dart';

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

    if (notesSnap.exists && notesSnap.value is Map) {
      final data = notesSnap.value as Map;
      for (var item in data.values) {
        if (item is Map &&
            item['OwnerId'] == userLogin &&
            item['Status'] == false) {
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
              // Dodać przywracanie usuniętej notatki
            },
          );
        },
      ),
    );
  }
}
