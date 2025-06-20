import 'package:Noteable/screens/home/shared_notes.dart';
import 'package:Noteable/screens/home/deleted_notes.dart';
import 'package:Noteable/utils/clipboard_manager.dart';
import 'package:Noteable/utils/note_downloader.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '/services/auth_service.dart';
import '/models/User.dart';
import '/models/Collaborator.dart';
import '/models/Folder.dart';
import '/models/Note.dart';
import '/screens/login/auth_page.dart';
import '/screens/home/new_note.dart';
import '/widgets/drawer.dart';
import 'package:intl/intl.dart';

class MyHomePage extends StatefulWidget {
  final String title;
  final int? folderId;

  const MyHomePage({super.key, required this.title, this.folderId});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Note? _clipboardNote;
  bool _isCutOperation = false;
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

  Future<List<User>> _fetchActiveUsers() async {
    final usersRef = _db.child('Users');
    final snapshot = await usersRef.get();

    if (snapshot.exists) {
      final Map data = snapshot.value as Map;
      return data.values
          .map((e) => User.fromJson(Map<String, dynamic>.from(e)))
          .where((u) => u.Status == true)
          .toList();
    } else {
      return [];
    }
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

  void _openNote(int noteId){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewNote(noteId: noteId),
      ),
    );
  }

  void _newNote() async {
    final TextEditingController nameController = TextEditingController();
    final newId = DateTime.now().millisecondsSinceEpoch;

    final bool? shouldCreate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowa notatka'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nazwa notatki'),
        ),
        actions: [
          TextButton(
            child: const Text('Anuluj'),
            onPressed: () => Navigator.pop(context, false), // zwróć false
          ),
          TextButton(
            child: const Text('Utwórz'),
            onPressed: () async {
              if (nameController.text.trim().isEmpty || _login == null) {
                Navigator.pop(context, false);
                return;
              }

              final newNoteRef = _db.child('Note').push();
              final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              final now = formatter.format(DateTime.now());

              final note = {
                'Id': newId,
                'Name': nameController.text.trim(),
                'CreationDate': now,
                'ModificationDate': now,
                'OwnerId': _login,
                'FolderId': widget.folderId ?? 0,
                'Status': true,
                'Content': "",
              };

              await newNoteRef.set(note);
              _loadData();

              Navigator.pop(context, true); // zwróć true
            },
          ),
        ],
      ),
    );

    // Przejdź do nowej notatki tylko jeśli użytkownik kliknął "Utwórz"
    if (shouldCreate == true) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NewNote(noteId: newId)),
      );
    }
  }

  void _editNoteName(Note note) {
    final _controller = TextEditingController(text: note.Name);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edytuj nazwę notatki'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: 'Nowa nazwa',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // zamknij dialog
              },
              child: const Text('Anuluj'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = _controller.text.trim();
                if (newName.isNotEmpty) {
                  final noteRef = _db.child('Note');
                  final snapshot = await noteRef.get();

                  if (snapshot.exists && snapshot.value is Map) {
                    final data = snapshot.value as Map;
                    for (var key in data.keys) {
                      final item = data[key];
                      if (item is Map && item['Id'] == note.Id) {
                        await noteRef.child(key).update({'Name': newName});
                        break;
                      }
                    }
                  }

                  Navigator.of(context).pop();
                  _loadData();
                }
              },
              child: const Text('Zapisz'),
            ),
          ],
        );
      },
    );
  }

  void _addCollaborator(Note note) async {
    List<User> users = await _fetchActiveUsers();
    User? selectedUser;

    if (users.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak aktywnych użytkowników')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Dodaj współtwórcę'),
            content: DropdownButtonFormField<User>(
              items: users.map((user) {
                return DropdownMenuItem<User>(
                  value: user,
                  child: Text('${user.Name} ${user.Surname} (${user.Login})'),
                );
              }).toList(),
              onChanged: (User? user) {
                setState(() {
                  selectedUser = user;
                });
              },
              hint: const Text('Wybierz użytkownika'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: selectedUser == null
                    ? null
                    : () async {
                  final collabRef = _db.child('Collaborators');
                  final snapshot = await collabRef.get();
                  int newId = 1;

                  if (snapshot.exists && snapshot.value is Map) {
                    final data = Map<String, dynamic>.from(snapshot.value as Map);
                    final ids = data.values.map((e) => e['Id'] as int).toList();
                    newId = (ids.isNotEmpty ? ids.reduce((a, b) => a > b ? a : b) + 1 : 1);
                  }

                  final newCollab = Collaborator(
                    Id: newId,
                    CollaboratorId: selectedUser!.Login,
                    NoteId: note.Id,
                  );

                  await collabRef.push().set(newCollab.toJson());

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dodano współtwórcę')),
                  );
                },
                child: const Text('Dodaj'),
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _deleteNote(int noteId) async {
    final noteRef = _db.child('Note');
    final snapshot = await noteRef.get();

    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map;
      for (var key in data.keys) {
        final item = data[key];
        if (item is Map && item['Id'] == noteId) {
          await noteRef.child(key).update({'Status': false});
          break;
        }
      }
    }

    // Odśwież widok
    _loadData();
  }

  void _downloadNote(Note note) {
    try {
      // Jeśli platforma mobilna – wymagany context
      // Jeśli web – context jest ignorowany
      downloadNote(note, context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Błąd podczas pobierania notatki: $e")),
      );
    }
  }

  void _newFolder() async {
    final TextEditingController nameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nowy folder'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nazwa folderu'),
        ),
        actions: [
          TextButton(
            child: const Text('Anuluj'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Utwórz'),
            onPressed: () async {
              Navigator.pop(context);

              if (nameController.text.trim().isEmpty || _login == null) return;

              final newFolderRef = _db.child('Folder').push();
              final newId = DateTime.now().millisecondsSinceEpoch;

              final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
              final now = formatter.format(DateTime.now());

              final folder = {
                'Id': newId,
                'Name': nameController.text.trim(),
                'CreationDate': now,
                'ModificationDate': now,
                'OwnerId': _login,
                'ParentFolderId': widget.folderId ?? 0,
                'Status': true,
              };

              await newFolderRef.set(folder);
              _loadData();
            },
          ),
        ],
      ),
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
              _openNote(n.Id);
            },
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'delete') {
                  _deleteNote(n.Id);
                } else if (value == 'addCollaborator') {
                  _addCollaborator(n);
                } else if (value == 'edit') {
                  _editNoteName(n);
                } else if (value == 'download') {
                  _downloadNote(n);
                } else if (value == 'copy') {
                  ClipboardManager.copy(n);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notatka skopiowana')),
                  );
                } else if (value == 'cut') {
                  ClipboardManager.cut(n);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notatka wycięta')),
                  );
                } else if (value == 'paste') {
                  await ClipboardManager.paste(_db);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notatka wklejona jako nowa')),
                  );
                  _loadData(); // odświeżenie widoku
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.yellow),
                      SizedBox(width: 8),
                      Text('Edytuj nazwę'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'addCollaborator',
                  child: Row(
                    children: [Icon(Icons.group_add, color: Colors.teal), SizedBox(width: 8), Text('Dodaj współtwórcę')],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Usuń'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Pobierz notatkę'),
                    ],
                  )
                ),
                const PopupMenuItem(
                    value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Kopiuj'),
                    ],
                  )
                ),
                const PopupMenuItem(
                    value: 'cut',
                    child: Row(
                      children: [
                        Icon(Icons.cut, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Wytnij'),
                      ],
                    )
                ),
                PopupMenuItem(
                    value: 'paste',
                    enabled: ClipboardManager.hasData(),
                    child: Row(
                      children: [
                        Icon(Icons.paste, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('Wklej'),
                      ],
                    )
                )
              ],
            ),
          )),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'folderBtn',
            onPressed: _newFolder,
            tooltip: 'Nowy folder',
            child: const Icon(Icons.create_new_folder),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'noteBtn',
            onPressed: _newNote,
            tooltip: 'Nowa notatka',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}
