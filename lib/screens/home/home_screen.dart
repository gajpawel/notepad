import 'package:Noteable/screens/home/shared_notes.dart';
import 'package:Noteable/screens/home/deleted_notes.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '/services/auth_service.dart';
import '/models/User.dart';
import '/models/Folder.dart';
import '/models/Note.dart';
import '/screens/login/auth_page.dart';
import '/screens/home/new_note.dart';
import '/widgets/drawer.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  final int? folderId;

  const MyHomePage({super.key, required this.title, this.folderId});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _db = FirebaseDatabase.instance.ref();
  String? _login;
  Folder? _currentFolder;

  List<Folder> _folders = [];
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    User? user = await AuthService.getCurrentUser();
    if (user == null) return;

    final userId = user.Login;
    setState(() {
      _login = user.Login;
    });

    final foldersSnap = await _db.child('Folder').get();
    final notesSnap = await _db.child('Note').get();

    List<Folder> folders = [];
    List<Note> notes = [];

    if (foldersSnap.exists && foldersSnap.value is Map) {
      final data = foldersSnap.value as Map;
      for (var item in data.values) {
        if (item is Map) {
          final folder = Folder.fromJson(Map<String, dynamic>.from(item));
          if (folder.OwnerId == userId &&
              (widget.folderId == null
                  ? folder.ParentFolderId == 0
                  : folder.ParentFolderId == widget.folderId)) {
            folders.add(folder);
          }
        }
      }
    }

    if (widget.folderId != null && foldersSnap.exists && foldersSnap.value is Map) {
      final data = foldersSnap.value as Map;
      for (var item in data.values) {
        if (item is Map) {
          final folder = Folder.fromJson(Map<String, dynamic>.from(item));
          if (folder.Id == widget.folderId) {
            _currentFolder = folder;
            break;
          }
        }
      }
    }

    if(widget.folderId == null || widget.folderId == 0) {
      final shared = Folder(Id: -2, Name: "Udostępnione", OwnerId: _login.toString(), ParentFolderId: 0, CreationDate: "", ModificationDate: "");
      folders.add(shared);
      final deleted = Folder(Id: -1, Name: "Kosz", OwnerId: _login.toString(), ParentFolderId: 0, CreationDate: "", ModificationDate: "");
      folders.add(deleted);
    }

    if (notesSnap.exists && notesSnap.value is Map) {
      final data = notesSnap.value as Map;
      for (var item in data.values) {
        if (item is Map) {
          final note = Note.fromJson(Map<String, dynamic>.from(item));
          if (note.OwnerId == userId && note.Status == true &&
              (widget.folderId == null
                  ? note.FolderId == 0 || note.FolderId == null
                  : note.FolderId == widget.folderId)) {
            notes.add(note);
          }
        }
      }
    }


    setState(() {
      _folders = folders;
      _notes = notes;
    });
  }

  void _openFolder(int folderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyHomePage(title: widget.title, folderId: folderId),
      ),
    );
  }

  void _openSpecialFolder(String specialType){
    if(specialType == "shared")
      {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SharedNotesPage(),
          ),
        );
      }
    else if(specialType == "deleted")
    {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeletedNotesPage(),
        ),
      );
    }
  }

  void _newNote() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewNote()),
    );
  }

  void _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (_login != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: Text('Witaj, $_login')),
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Wyloguj',
          ),
        ],
      ),

      drawer: AppDrawer(),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.folderId == null || widget.folderId == 0
                        ? '📓 Mój notes'
                        : '📁 ${_currentFolder?.Name ?? "Folder"}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: 'Wróć do folderu nadrzędnego',
                  onPressed: widget.folderId == null || widget.folderId == 0
                      ? null
                      : () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MyHomePage(
                          title: widget.title,
                          folderId: _currentFolder?.ParentFolderId == 0
                              ? null
                              : _currentFolder?.ParentFolderId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("📁 Foldery", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ..._folders.map((f) => ListTile(
            leading: f.Id == -1 ? const Icon(Icons.delete, color: Colors.blue) : f.Id == -2 ? Icon(Icons.folder_shared, color: Colors.blue) : Icon(Icons.folder),
            title: Text(f.Name),
            onTap: () => f.Id == -1 ? _openSpecialFolder("deleted") : f.Id == -2 ? _openSpecialFolder("shared") : _openFolder(f.Id),
          )),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text("📝 Notatki", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ..._notes.map((n) => ListTile(
            leading: const Icon(Icons.note),
            title: Text(n.Name),
            onTap: () {
              // Możesz dodać ekran wyświetlania notatki
            },
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newNote,
        tooltip: 'Nowa notatka',
        child: const Icon(Icons.add),
      ),
    );
  }
}
