import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '/services/auth_service.dart';
import '/models/Note.dart';
import '/models/Folder.dart';
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
  List<Folder> _deletedFolders = [];

  @override
  void initState() {
    super.initState();
    _loadDeletedData();
  }

  Future<void> _loadDeletedData() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return;

    final userLogin = user.Login;
    setState(() {
      _login = userLogin;
    });

    final notesSnap = await _db.child('Note').get();
    final foldersSnap = await _db.child('Folder').get();

    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    List<Note> deletedNotes = [];
    List<Folder> deletedFolders = [];

    // Notatki
    if (notesSnap.exists && notesSnap.value is Map) {
      final data = notesSnap.value as Map;
      for (var entry in data.entries) {
        final key = entry.key;
        final item = entry.value;

        if (item is Map &&
            item['OwnerId'] == userLogin &&
            item['Status'] == false) {
          try {
            final modDate = formatter.parse(item['ModificationDate'] ?? '');
            if (now.difference(modDate).inDays > 30) {
              await _db.child('Note').child(key).remove();
              continue;
            }
          } catch (e) {
            print('Błąd parsowania daty notatki: ${item['ModificationDate']} - $e');
          }

          deletedNotes.add(Note.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    // Foldery
    if (foldersSnap.exists && foldersSnap.value is Map) {
      final data = foldersSnap.value as Map;
      for (var entry in data.entries) {
        final key = entry.key;
        final item = entry.value;

        if (item is Map &&
            item['OwnerId'] == userLogin &&
            item['Status'] == false) {
          try {
            final modDate = formatter.parse(item['ModificationDate'] ?? '');
            if (now.difference(modDate).inDays > 30) {
              await _db.child('Folder').child(key).remove();
              continue;
            }
          } catch (e) {
            print('Błąd parsowania daty folderu: ${item['ModificationDate']} - $e');
          }

          deletedFolders.add(Folder.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    setState(() {
      _deletedNotes = deletedNotes;
      _deletedFolders = deletedFolders;
    });
  }

  void _noteBinActions(Note note) {
    _showActionDialog(
      title: 'notatki "${note.Name}"',
      onRestore: () async {
        await _db
            .child('Note')
            .orderByChild('Id')
            .equalTo(note.Id)
            .once()
            .then((snap) {
          if (snap.snapshot.value != null) {
            final key = (snap.snapshot.value as Map).keys.first;
            _db.child('Note').child(key).update({
              'Status': true,
              'ModificationDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
            });
          }
        });
        _loadDeletedData();
      },
      onDelete: () async {
        await _db
            .child('Note')
            .orderByChild('Id')
            .equalTo(note.Id)
            .once()
            .then((snap) {
          if (snap.snapshot.value != null) {
            final key = (snap.snapshot.value as Map).keys.first;
            _db.child('Note').child(key).remove();
          }
        });
        _loadDeletedData();
      },
    );
  }

  void _folderBinActions(Folder folder) {
    _showActionDialog(
      title: 'folderu "${folder.Name}"',
      onRestore: () async {
        await _db
            .child('Folder')
            .orderByChild('Id')
            .equalTo(folder.Id)
            .once()
            .then((snap) {
          if (snap.snapshot.value != null) {
            final key = (snap.snapshot.value as Map).keys.first;
            _db.child('Folder').child(key).update({
              'Status': true,
              'ModificationDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
            });
          }
        });
        _loadDeletedData();
      },
      onDelete: () async {
        await _db
            .child('Folder')
            .orderByChild('Id')
            .equalTo(folder.Id)
            .once()
            .then((snap) {
          if (snap.snapshot.value != null) {
            final key = (snap.snapshot.value as Map).keys.first;
            _db.child('Folder').child(key).remove();
          }
        });
        _loadDeletedData();
      },
    );
  }

  void _showActionDialog({
    required String title,
    required Future<void> Function() onRestore,
    required Future<void> Function() onDelete,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Wybierz akcję dla $title'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Anuluj')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await onDelete();
            },
            child: const Text('Usuń trwale', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await onRestore();
            },
            child: const Text('Przywróć'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("🗑️ Kosz")),
      body: ListView(
        children: [
          if (_deletedNotes.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Usunięte notatki", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ..._deletedNotes.map((note) => ListTile(
              leading: const Icon(Icons.note),
              title: Text(note.Name),
              subtitle: Text("Usunięto: ${note.ModificationDate}"),
              onTap: () => _noteBinActions(note),
            )),
          ],
          if (_deletedFolders.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Usunięte foldery", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ..._deletedFolders.map((folder) => ListTile(
              leading: const Icon(Icons.folder),
              title: Text(folder.Name),
              subtitle: Text("Usunięto: ${folder.ModificationDate}"),
              onTap: () => _folderBinActions(folder),
            )),
          ],
          if (_deletedNotes.isEmpty && _deletedFolders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(child: Text("Kosz jest pusty")),
            ),
        ],
      ),
    );
  }
}
