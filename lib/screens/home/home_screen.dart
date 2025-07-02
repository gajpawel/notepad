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
import 'package:intl/intl.dart';

import '/utils/download_helper.dart';
import '/utils/zip_utils.dart';

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
      _login = userId;
      _currentFolder = null;
      _folders = [];
      _notes = [];
    });

    final foldersSnap = await _db.child('Folder').get();
    final notesSnap = await _db.child('Note').get();

    List<Folder> folders = [];
    List<Note> notes = [];

    // Wczytywanie folderów
    if (foldersSnap.exists && foldersSnap.value is Map) {
      final data = foldersSnap.value as Map;
      for (var item in data.values) {
        if (item is Map) {
          try {
            final folder = Folder.fromJson(Map<String, dynamic>.from(item));

            // Widok kosza
            if (widget.folderId == -1) {
              if (folder.OwnerId == userId && folder.Status == false) {
                folders.add(folder);
              }
            }
            // Widok normalny
            else if (folder.OwnerId == userId &&
                folder.Status == true &&
                (widget.folderId == null
                    ? folder.ParentFolderId == 0
                    : folder.ParentFolderId == widget.folderId)) {
              folders.add(folder);
            }
          } catch (e) {
            print('Błąd parsowania folderu: $e');
          }
        }
      }
    }

    // Wczytywanie bieżącego folderu (nagłówek)
    if (widget.folderId != null &&
        widget.folderId != -1 &&
        foldersSnap.exists &&
        foldersSnap.value is Map) {
      final data = foldersSnap.value as Map;
      for (var item in data.values) {
        if (item is Map) {
          try {
            final folder = Folder.fromJson(Map<String, dynamic>.from(item));
            if (folder.Id == widget.folderId) {
              _currentFolder = folder;
              break;
            }
          } catch (e) {
            print('Błąd parsowania folderu dla _currentFolder: $e');
          }
        }
      }
    }

    // Dodanie folderów domyślnych (Udostępnione, Kosz)
    if (widget.folderId == null || widget.folderId == 0) {
      final defaultOwnerId = _login ?? 'default_user';
      folders.addAll([
        Folder(
          Id: -2,
          Name: "Udostępnione",
          OwnerId: defaultOwnerId,
          ParentFolderId: 0,
          CreationDate: DateTime.now(),
          ModificationDate: DateTime.now(),
          Status: true,
        ),
        Folder(
          Id: -1,
          Name: "Kosz",
          OwnerId: defaultOwnerId,
          ParentFolderId: 0,
          CreationDate: DateTime.now(),
          ModificationDate: DateTime.now(),
          Status: true,
        ),
      ]);
    }

    // Wczytywanie notatek
    if (notesSnap.exists && notesSnap.value is Map) {
      final data = notesSnap.value as Map;
      for (var item in data.values) {
        if (item is Map) {
          try {
            final note = Note.fromJson(Map<String, dynamic>.from(item));

            if (note.OwnerId == userId) {
              if (widget.folderId == -1 && note.Status == false) {
                // Notatki w koszu
                notes.add(note);
              } else if (widget.folderId != -1 &&
                  note.Status == true &&
                  (widget.folderId == null
                      ? note.FolderId == 0 || note.FolderId == null
                      : note.FolderId == widget.folderId)) {
                // Notatki normalne
                notes.add(note);
              }
            }
          } catch (e) {
            print('Błąd parsowania notatki: $e');
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
    try {
      final usersRef = _db.child('Users');
      final snapshot = await usersRef.get();

      if (snapshot.exists && snapshot.value is Map) {
        final Map data = snapshot.value as Map;
        List<User> users = [];
        
        for (var userValue in data.values) {
          if (userValue is Map) {
            try {
              final user = User.fromJson(Map<String, dynamic>.from(userValue));
              if (user.Status) {
                users.add(user);
              }
            } catch (e) {
              print('Błąd parsowania użytkownika: $e');
            }
          }
        }
        
        return users;
      } else {
        return [];
      }
    } catch (e) {
      print('Błąd w _fetchActiveUsers: $e');
      return [];
    }
  }

  void _openFolder(int folderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MyHomePage(title: widget.title, folderId: folderId),
      ),
    );
  }

  void _openSpecialFolder(String specialType) {
    if (specialType == "shared") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SharedNotesPage()),
      );
    } else if (specialType == "deleted") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DeletedNotesPage()),
      );
    }
  }

  void _openNote(int noteId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewNote(noteId: noteId)),
    );
  }

  void _newNote() async {
    final TextEditingController nameController = TextEditingController();
    final newId = DateTime.now().millisecondsSinceEpoch;

    final bool? shouldCreate = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nowa notatka'),
            content: TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nazwa notatki'),
            ),
            actions: [
              TextButton(
                child: const Text('Anuluj'),
                onPressed: () => Navigator.pop(context, false),
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

                  Navigator.pop(context, true);
                },
              ),
            ],
          ),
    );

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
            decoration: const InputDecoration(labelText: 'Nowa nazwa'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
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
  try {
    print('DEBUG: === ROZPOCZYNAM _addCollaborator ===');
    print('DEBUG: Note ID: ${note.Id}');
    print('DEBUG: Note Name: ${note.Name}');
    print('DEBUG: Current login: $_login');

    List<User> users = [];
    List<MapEntry<String, Collaborator>> existingCollaborators = [];
    TextEditingController emailController = TextEditingController();
    User? selectedUser;
    User? foundUserByEmail;
    String currentLogin = _login ?? '';

    // Pobierz użytkowników z bardzo szczegółowym debugowaniem
    try {
      print('DEBUG: Pobieram użytkowników...');
      final usersRef = _db.child('Users');
      final usersSnapshot = await usersRef.get();
      
      if (usersSnapshot.exists && usersSnapshot.value is Map) {
        final usersData = usersSnapshot.value as Map;
        print('DEBUG: Znaleziono ${usersData.length} rekordów użytkowników');
        
        for (var entry in usersData.entries) {
          try {
            print('DEBUG: Przetwarzam użytkownika: klucz=${entry.key}');
            
            if (entry.value is Map) {
              final userMap = Map<String, dynamic>.from(entry.value);
              print('DEBUG: Dane użytkownika: $userMap');
              
              // Sprawdź każde pole osobno
              final uid = userMap['Uid'];
              final login = userMap['Login'];
              final email = userMap['Email'];
              final name = userMap['Name'];
              final surname = userMap['Surname'];
              final status = userMap['Status'];
              final theme = userMap['Theme'];
              
              print('DEBUG: Uid=$uid, Login=$login, Email=$email, Name=$name, Surname=$surname, Status=$status, Theme=$theme');
              
              // Bezpieczne tworzenie użytkownika
              if (login != null && login.toString().isNotEmpty) {
                final user = User(
                  Uid: uid?.toString() ?? '',
                  Login: login.toString(),
                  Email: email?.toString() ?? '',
                  Name: name?.toString() ?? '',
                  Surname: surname?.toString() ?? '',
                  Status: status == true,
                  Theme: theme == true,
                );
                
                if (user.Status) {
                  users.add(user);
                  print('DEBUG: Dodano użytkownika: ${user.Login}');
                }
              } else {
                print('DEBUG: Pominięto użytkownika z pustym loginem');
              }
            }
          } catch (e) {
            print('DEBUG: Błąd parsowania użytkownika: $e');
          }
        }
      }
      
      print('DEBUG: Łącznie załadowano ${users.length} aktywnych użytkowników');
    } catch (e) {
      print('DEBUG: Błąd podczas pobierania użytkowników: $e');
      throw e;
    }

    // Pobierz współtwórców z bardzo szczegółowym debugowaniem
    try {
      print('DEBUG: Pobieram współtwórców...');
      final collabRef = _db.child('Collaborators');
      final collabSnap = await collabRef.get();

      if (collabSnap.exists && collabSnap.value is Map) {
        final collabData = Map<String, dynamic>.from(collabSnap.value as Map);
        print('DEBUG: Znaleziono ${collabData.length} rekordów współtwórców');
        
        for (var entry in collabData.entries) {
          try {
            print('DEBUG: Przetwarzam współtwórcę: klucz=${entry.key}');
            
            if (entry.value is Map) {
              final collabMap = Map<String, dynamic>.from(entry.value);
              print('DEBUG: Dane współtwórcy: $collabMap');
              
              final id = collabMap['Id'];
              final collaboratorId = collabMap['CollaboratorId'];
              final noteId = collabMap['NoteId'];
              
              print('DEBUG: Id=$id, CollaboratorId=$collaboratorId, NoteId=$noteId');
              
              // Sprawdź czy to współtwórca dla tej notatki
              if (noteId != null && 
                  (noteId == note.Id || noteId.toString() == note.Id.toString())) {
                
                print('DEBUG: To współtwórca dla naszej notatki');
                
                // Bardzo bezpieczne tworzenie współtwórcy
                final collaborator = Collaborator(
                  Id: id is int ? id : (int.tryParse(id?.toString() ?? '0') ?? 0),
                  CollaboratorId: collaboratorId?.toString() ?? '',
                  NoteId: noteId is int ? noteId : (int.tryParse(noteId?.toString() ?? '0') ?? 0),
                );
                
                if (collaborator.CollaboratorId.isNotEmpty) {
                  existingCollaborators.add(MapEntry(entry.key, collaborator));
                  print('DEBUG: Dodano współtwórcę: ${collaborator.CollaboratorId}');
                }
              }
            }
          } catch (e) {
            print('DEBUG: Błąd parsowania współtwórcy: $e');
          }
        }
      }
      
      print('DEBUG: Łącznie załadowano ${existingCollaborators.length} współtwórców');
    } catch (e) {
      print('DEBUG: Błąd podczas pobierania współtwórców: $e');
      throw e;
    }

    // Funkcja do wyszukiwania użytkownika po e-mailu
    Future<User?> searchUserByEmail(String email) async {
      print('DEBUG: Wyszukuję użytkownika po e-mailu: $email');
      
      if (email.trim().isEmpty) {
        print('DEBUG: Pusty e-mail');
        return null;
      }
      
      try {
        for (var user in users) {
          print('DEBUG: Sprawdzam użytkownika: ${user.Login}, email: ${user.Email}');
          if (user.Email.toLowerCase() == email.toLowerCase()) {
            print('DEBUG: Znaleziono użytkownika po e-mailu: ${user.Login}');
            return user;
          }
        }
        print('DEBUG: Nie znaleziono użytkownika po e-mailu');
      } catch (e) {
        print('DEBUG: Błąd podczas wyszukiwania po e-mailu: $e');
      }
      return null;
    }

    if (!mounted) {
      print('DEBUG: Widget nie jest mounted, przerywam');
      return;
    }

    print('DEBUG: Pokazuję dialog');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Współtwórcy'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sekcja wyszukiwania po e-mailu
                  const Text(
                    'Wyszukaj po e-mailu:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            hintText: 'Wprowadź adres e-mail',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              foundUserByEmail = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final email = emailController.text.trim();
                          if (email.isNotEmpty) {
                            try {
                              final user = await searchUserByEmail(email);
                              setDialogState(() {
                                foundUserByEmail = user;
                                if (user != null) {
                                  selectedUser = user;
                                }
                              });
                              
                              if (user == null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Nie znaleziono użytkownika o podanym e-mailu'),
                                  ),
                                );
                              }
                            } catch (e) {
                              print('DEBUG: Błąd podczas wyszukiwania: $e');
                            }
                          }
                        },
                        child: const Text('Szukaj'),
                      ),
                    ],
                  ),
                  
                  if (foundUserByEmail != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Znaleziono: ${foundUserByEmail!.Name} ${foundUserByEmail!.Surname} (${foundUserByEmail!.Login})',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Alternatywnie: wybierz z listy
                  const Text(
                    'Lub wybierz z listy:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<User>(
                    value: selectedUser,
                    items: users
                        .where((user) => 
                            user.Login != currentLogin && 
                            user.Login.isNotEmpty)
                        .map((user) => DropdownMenuItem<User>(
                              value: user,
                              child: Text(
                                '${user.Name} ${user.Surname} (${user.Login})',
                              ),
                            ))
                        .toList(),
                    onChanged: (User? user) {
                      setDialogState(() {
                        selectedUser = user;
                        if (user != null) {
                          foundUserByEmail = user;
                          emailController.clear();
                        }
                      });
                    },
                    hint: const Text('Wybierz użytkownika'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Aktualni współtwórcy:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (existingCollaborators.isEmpty)
                    const Text(
                      'Brak współtwórców',
                      style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                    )
                  else
                    ...existingCollaborators.map((entry) => ListTile(
                          title: Text(entry.value.CollaboratorId),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              try {
                                print('DEBUG: Usuwam współtwórcę: ${entry.key}');
                                await _db
                                    .child('Collaborators')
                                    .child(entry.key)
                                    .remove();
                                
                                setDialogState(() {
                                  existingCollaborators.removeWhere(
                                    (e) => e.key == entry.key,
                                  );
                                });
                                
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Usunięto współtwórcę ${entry.value.CollaboratorId}',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                print('DEBUG: Błąd podczas usuwania współtwórcy: $e');
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Błąd podczas usuwania współtwórcy'),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Zamknij'),
              ),
              ElevatedButton(
                onPressed: selectedUser == null
                    ? null
                    : () async {
                        try {
                          print('DEBUG: === DODAJĘ WSPÓŁTWÓRCĘ ===');
                          print('DEBUG: Wybrany użytkownik: ${selectedUser!.Login}');
                          
                          // Sprawdź czy selectedUser ma login
                          if (selectedUser!.Login.isEmpty) {
                            print('DEBUG: Pusty login');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Błąd: Użytkownik nie ma przypisanego loginu'),
                                ),
                              );
                            }
                            return;
                          }

                          // Sprawdź czy użytkownik już istnieje
                          final alreadyExists = existingCollaborators.any(
                            (entry) => entry.value.CollaboratorId == selectedUser!.Login,
                          );

                          if (alreadyExists) {
                            print('DEBUG: Użytkownik już istnieje');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ten użytkownik już ma dostęp'),
                                ),
                              );
                            }
                            return;
                          }

                          print('DEBUG: Tworzę nowy rekord współtwórcy');

                          // Użyj push() do stworzenia nowego klucza
                          final newCollabRef = _db.child('Collaborators').push();
                          
                          // Wygeneruj nowe ID
                          int newId = DateTime.now().millisecondsSinceEpoch;

                          final collaboratorData = {
                            'Id': newId,
                            'CollaboratorId': selectedUser!.Login,
                            'NoteId': note.Id,
                          };

                          print('DEBUG: Zapisuję dane: $collaboratorData');

                          await newCollabRef.set(collaboratorData);
                          
                          print('DEBUG: Zapisano pomyślnie');

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Dodano współtwórcę: ${selectedUser!.Login}',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('DEBUG: Błąd podczas dodawania współtwórcy: $e');
                          print('DEBUG: Stack trace: ${StackTrace.current}');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Błąd podczas dodawania współtwórcy: $e'),
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Dodaj'),
              ),
            ],
          ),
        );
      },
    );
  } catch (e, stackTrace) {
    print('DEBUG: === GŁÓWNY BŁĄD W _addCollaborator ===');
    print('DEBUG: Błąd: $e');
    print('DEBUG: Stack trace: $stackTrace');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Błąd podczas ładowania współtwórców: $e'),
        ),
      );
    }
  }
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

    _loadData();
  }

  Future<void> _downloadNote(Note note) async {
    try {
      final noteRef = _db.child('Note');
      final snapshot = await noteRef.get();

      if (snapshot.exists && snapshot.value is Map) {
        final data = snapshot.value as Map;
        for (var item in data.values) {
          if (item is Map && item['Id'] == note.Id) {
            note = Note.fromJson(Map<String, dynamic>.from(item));
            break;
          }
        }
      }

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
      builder:
          (context) => AlertDialog(
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

                  if (nameController.text.trim().isEmpty || _login == null)
                    return;

                  final newId = DateTime.now().millisecondsSinceEpoch;
                  final newFolderRef = _db
                      .child('Folder')
                      .child(newId.toString());

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

  void _editFolderName(Folder folder) async {
    final controller = TextEditingController(text: folder.Name);
    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Zmień nazwę folderu'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Nowa nazwa'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Anuluj'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Zapisz'),
              ),
            ],
          ),
    );

    if (newName != null && newName.trim().isNotEmpty) {
      await _db.child('Folder/${folder.Id}').update({
        'Name': newName.trim(),
        'ModificationDate': DateTime.now().toIso8601String(),
      });

      print('Zmieniono nazwę folderu: ${folder.Name} -> $newName');
      _loadData();
    }
  }

  void _copyFolder(Folder folder) {
    ClipboardManager.copyFolder(folder);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Folder skopiowany')));
    print('Skopiowano folder: ${folder.Name}');
  }

  void _cutFolder(Folder folder) {
    ClipboardManager.cutFolder(folder, _db);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Folder wycięty')));
    print('Wytnięto folder: ${folder.Name}');
  }

  Future<void> _pasteFolder(int? parentFolderId) async {
    await ClipboardManager.pasteFolder(_db, parentFolderId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Folder wklejony')));
    print('Wklejono folder do folderu: $parentFolderId');
    _loadData();
  }

  void _deleteFolder(Folder folder) async {
    await _db.child('Folder/${folder.Id}').update({'Status': false});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Folder usunięty')));
    print('Usunięto folder: ${folder.Name}');
    _loadData();
  }

  Future<List<Note>> getAllNotesRecursive(int folderId) async {
    final List<Note> allNotes = [];

    final notesSnap = await _db.child('Note').get();
    if (notesSnap.exists && notesSnap.value is Map) {
      final data = notesSnap.value as Map;
      data.forEach((key, value) {
        if (value is Map &&
            value['FolderId'] == folderId &&
            value['Status'] == true) {
          allNotes.add(Note.fromJson(Map<String, dynamic>.from(value)));
        }
      });
    }

    final foldersSnap = await _db.child('Folder').get();
    if (foldersSnap.exists && foldersSnap.value is Map) {
      final folderData = foldersSnap.value as Map;
      for (var item in folderData.values) {
        if (item is Map &&
            item['ParentFolderId'] == folderId &&
            item['Status'] == true) {
          final subfolderId = item['Id'] as int;
          final childNotes = await getAllNotesRecursive(subfolderId);
          allNotes.addAll(childNotes);
        }
      }
    }

    return allNotes;
  }

  Future<void> downloadFolderAsZip(Folder folder, List<Note> notes) async {
    final zipBytes = createZipInMemory(folder, notes);
    await saveZipFile(zipBytes, '${folder.Name}.zip');
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
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_upward),
                  tooltip: 'Wróć do folderu nadrzędnego',
                  onPressed:
                      widget.folderId == null || widget.folderId == 0
                          ? null
                          : () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => MyHomePage(
                                      title: widget.title,
                                      folderId:
                                          _currentFolder?.ParentFolderId == 0
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
            child: Text(
              "📁 Foldery",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ..._folders.map(
            (f) => ListTile(
              leading:
                  f.Id == -1
                      ? const Icon(Icons.delete, color: Colors.blue)
                      : f.Id == -2
                      ? const Icon(Icons.folder_shared, color: Colors.blue)
                      : const Icon(Icons.folder),
              title: Text(f.Name),
              onTap:
                  () =>
                      f.Id == -1
                          ? _openSpecialFolder("deleted")
                          : f.Id == -2
                          ? _openSpecialFolder("shared")
                          : _openFolder(f.Id),
              trailing:
                  (f.Id == -1 || f.Id == -2)
                      ? null
                      : PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'delete') {
                            _deleteFolder(f);
                          } else if (value == 'edit') {
                            _editFolderName(f);
                          } else if (value == 'copy') {
                            _copyFolder(f);
                          } else if (value == 'cut') {
                            _cutFolder(f);
                          } else if (value == 'paste') {
                            await _pasteFolder(f.Id);
                          } else if (value == 'download') {
                            final notes = await getAllNotesRecursive(f.Id);
                            await downloadFolderAsZip(f, notes);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Folder pobrany jako ZIP'),
                              ),
                            );
                          }
                        },
                        itemBuilder:
                            (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, color: Colors.yellow),
                                    SizedBox(width: 8),
                                    Text('Edytuj nazwę'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
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
                                value: 'copy',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy, color: Colors.yellow),
                                    SizedBox(width: 8),
                                    Text('Kopiuj'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'cut',
                                child: Row(
                                  children: [
                                    Icon(Icons.cut, color: Colors.orange),
                                    SizedBox(width: 8),
                                    Text('Wytnij'),
                                  ],
                                ),
                              ),
                              if (ClipboardManager.hasFolder())
                                const PopupMenuItem(
                                  value: 'paste',
                                  child: Row(
                                    children: [
                                      Icon(Icons.paste, color: Colors.purple),
                                      SizedBox(width: 8),
                                      Text('Wklej'),
                                    ],
                                  ),
                                ),
                              const PopupMenuItem(
                                value: 'download',
                                child: Row(
                                  children: [
                                    Icon(Icons.download, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('Pobierz jako ZIP'),
                                  ],
                                ),
                              ),
                            ],
                      ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "📝 Notatki",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ..._notes.map(
            (n) => ListTile(
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notatka skopiowana')),
                    );
                  } else if (value == 'cut') {
                    ClipboardManager.cut(n, _db);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notatka wycięta')),
                    );
                    await _loadData();
                  } else if (value == 'paste') {
                    await ClipboardManager.paste(_db, widget.folderId ?? 0);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notatka wklejona jako nowa'),
                      ),
                    );
                    await _loadData();
                  }
                },
                itemBuilder:
                    (BuildContext context) => <PopupMenuEntry<String>>[
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
                          children: [
                            Icon(Icons.group_add, color: Colors.teal),
                            SizedBox(width: 8),
                            Text('Dodaj współtwórcę'),
                          ],
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
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Kopiuj'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'cut',
                        child: Row(
                          children: [
                            Icon(Icons.cut, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Wytnij'),
                          ],
                        ),
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
                        ),
                      ),
                    ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (ClipboardManager.hasData()) ...[
            FloatingActionButton(
              heroTag: 'pasteNoteBtn',
              onPressed: () async {
                await ClipboardManager.paste(_db, widget.folderId ?? 0);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notatka wklejona')),
                );
                _loadData();
              },
              tooltip: 'Wklej notatkę',
              child: const Icon(Icons.paste),
            ),
            const SizedBox(height: 12),
          ],
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