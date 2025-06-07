import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '/services/auth_service.dart';
import '/models/User.dart';
import '/models/Note.dart';

class SharedNotesPage extends StatefulWidget {
  const SharedNotesPage({super.key});

  @override
  State<SharedNotesPage> createState() => _SharedNotesPageState();
}

class _SharedNotesPageState extends State<SharedNotesPage> {
  final _db = FirebaseDatabase.instance.ref();
  String? _login;
  List<Note> _sharedNotes = [];

  @override
  void initState() {
    super.initState();
    _loadSharedNotes();
  }

  Future<void> _loadSharedNotes() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return;

    final userLogin = user.Login;
    setState(() {
      _login = userLogin;
    });

    final collaboratorsSnap = await _db.child('Collaborator').get();
    final notesSnap = await _db.child('Note').get();

    Set<String> sharedNoteIds = {};

    // Znajdź wszystkie NoteId przypisane do użytkownika w tabeli Collaborator
    if (collaboratorsSnap.exists && collaboratorsSnap.value is Map) {
      final data = collaboratorsSnap.value as Map;
      for (var item in data.values) {
        if (item is Map &&
            item['CollaboratorId'] == userLogin &&
            item['NoteId'] != null) {
          sharedNoteIds.add(item['NoteId'].toString());
        }
      }
    }

    List<Note> sharedNotes = [];

    // Pobierz odpowiadające notatki
    if (notesSnap.exists && notesSnap.value is Map) {
      final data = notesSnap.value as Map;
      for (var item in data.values) {
        if (item is Map) {
          final note = Note.fromJson(Map<String, dynamic>.from(item));
          if (sharedNoteIds.contains(note.Id.toString()) && note.Status == true) {
            sharedNotes.add(note);
          }
        }
      }
    }

    setState(() {
      _sharedNotes = sharedNotes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📂 Udostępnione notatki"),
      ),
      body: _sharedNotes.isEmpty
          ? const Center(child: Text("Brak udostępnionych notatek"))
          : ListView.builder(
        itemCount: _sharedNotes.length,
        itemBuilder: (context, index) {
          final note = _sharedNotes[index];
          return ListTile(
            leading: const Icon(Icons.note_alt_outlined),
            title: Text(note.Name),
            subtitle: Text("Data modyfikacji: ${note.ModificationDate}"),
            onTap: () {
              // Możesz dodać ekran otwierania notatki
            },
          );
        },
      ),
    );
  }
}
