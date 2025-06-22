import 'package:firebase_database/firebase_database.dart';
import '../models/Note.dart';
import '../models/Folder.dart';

class ClipboardManager {
  static Note? _clipboardNote;
  static Folder? _clipboardFolder;
  static bool _isCutOperation = false;
  static bool _isFolderClipboard = false;

  // Obsługa notatek
  static void copy(Note note) {
    _clipboardNote = note;
    _clipboardFolder = null;
    _isCutOperation = false;
    _isFolderClipboard = false;
  }

  static Future<void> cut(Note note, DatabaseReference db) async {
    _clipboardNote = note;
    _clipboardFolder = null;
    _isCutOperation = true;
    _isFolderClipboard = false;

    // Ustaw Status=false aby zniknęła z widoku
    final notesSnap = await db.child('Note').get();
    if (notesSnap.exists && notesSnap.value is Map) {
      final data = notesSnap.value as Map;
      for (var entry in data.entries) {
        if (entry.value is Map && entry.value['Id'] == note.Id) {
          await db.child('Note').child(entry.key).update({'Status': false});
          break;
        }
      }
    }
  }

  static bool hasData() => _clipboardNote != null;
  static bool hasFolder() => _clipboardFolder != null;

  static Future<void> paste(DatabaseReference db, int folderId) async {
    if (_clipboardNote == null) return;

    final now = DateTime.now().toIso8601String();
    final baseName = _clipboardNote!.Name;
    String newName = '$baseName (kopia)';
    int count = 0;

    final notesSnap = await db.child('Note').get();
    if (notesSnap.exists && notesSnap.value is Map) {
      final data = notesSnap.value as Map;
      for (var item in data.values) {
        if (item is Map && item['Name'] != null) {
          final name = item['Name'] as String;
          if (name.startsWith(baseName)) {
            final suffix = name.replaceFirst(baseName, '').trim();
            if (suffix == '(kopia)') {
              count = count < 1 ? 1 : count;
            } else if (RegExp(r'\(kopia (\d+)\)').hasMatch(suffix)) {
              final match = RegExp(r'\(kopia (\d+)\)').firstMatch(suffix);
              if (match != null) {
                final num = int.tryParse(match.group(1)!);
                if (num != null && num > count) {
                  count = num;
                }
              }
            }
          }
        }
      }
    }

    if (count > 0) {
      newName = '$baseName (kopia ${count + 1})';
    }

    final newNoteId = DateTime.now().millisecondsSinceEpoch;
    final newNote = Note(
      Id: newNoteId,
      Name: newName,
      OwnerId: _clipboardNote!.OwnerId,
      FolderId: folderId,
      CreationDate: DateTime.now(),
      ModificationDate: DateTime.now(),
      Content: _clipboardNote!.Content,
      Status: true,
    );

    await db.child('Note').child(newNoteId.toString()).set(newNote.toJson());

    _clipboardNote = null;
    _isCutOperation = false;
  }

  // Obsługa folderów
  static void copyFolder(Folder folder) {
    _clipboardFolder = folder;
    _clipboardNote = null;
    _isCutOperation = false;
    _isFolderClipboard = true;
  }

  static Future<void> cutFolder(Folder folder, DatabaseReference db) async {
    _clipboardFolder = folder;
    _clipboardNote = null;
    _isCutOperation = true;
    _isFolderClipboard = true;

    // Ustaw Status=false aby zniknął z widoku
    final foldersSnap = await db.child('Folder').get();
    if (foldersSnap.exists && foldersSnap.value is Map) {
      final data = foldersSnap.value as Map;
      for (var entry in data.entries) {
        if (entry.value is Map && entry.value['Id'] == folder.Id) {
          await db.child('Folder').child(entry.key).update({'Status': false});
          break;
        }
      }
    }
  }

  static Future<void> pasteFolder(DatabaseReference db, int? targetParentFolderId) async {
    if (_clipboardFolder == null) return;

    final now = DateTime.now();
    final baseName = _clipboardFolder!.Name;
    String newName = '$baseName (kopia)';
    int count = 0;

    final foldersSnap = await db.child('Folder').get();
    if (foldersSnap.exists && foldersSnap.value is Map) {
      final data = foldersSnap.value as Map;
      for (var item in data.values) {
        if (item is Map && item['Name'] != null) {
          final name = item['Name'] as String;
          if (name.startsWith(baseName)) {
            final suffix = name.replaceFirst(baseName, '').trim();
            if (suffix == '(kopia)') {
              count = count < 1 ? 1 : count;
            } else if (RegExp(r'\(kopia (\d+)\)').hasMatch(suffix)) {
              final match = RegExp(r'\(kopia (\d+)\)').firstMatch(suffix);
              if (match != null) {
                final num = int.tryParse(match.group(1)!);
                if (num != null && num > count) {
                  count = num;
                }
              }
            }
          }
        }
      }
    }

    if (count > 0) {
      newName = '$baseName (kopia ${count + 1})';
    }

    final newFolderId = DateTime.now().millisecondsSinceEpoch;
    final newFolder = Folder(
      Id: newFolderId,
      Name: newName,
      OwnerId: _clipboardFolder!.OwnerId,
      ParentFolderId: targetParentFolderId ?? 0,
      CreationDate: now,
      ModificationDate: now,
      Status: true,
    );

    await db.child('Folder').child(newFolderId.toString()).set(newFolder.toJson());

    _clipboardFolder = null;
    _isCutOperation = false;
  }
}

