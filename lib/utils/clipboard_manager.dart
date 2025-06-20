import 'package:firebase_database/firebase_database.dart';
import '../models/Note.dart';

class ClipboardManager {
  static Note? _clipboardNote;
  static bool _isCutOperation = false;

  static void copy(Note note) {
    _clipboardNote = note;
    _isCutOperation = false;
  }

  static void cut(Note note) {
    _clipboardNote = note;
    _isCutOperation = true;
  }

  static bool hasData() => _clipboardNote != null;

  static Future<void> paste(DatabaseReference db) async {
    if (_clipboardNote == null) return;

    final now = DateTime.now().toIso8601String();
    final baseName = _clipboardNote!.Name;
    String newName = '$baseName (kopia)';

    // Pobierz wszystkie notatki i znajdź podobne nazwy
    final notesSnap = await db.child('Note').get();
    int count = 0;

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
      FolderId: _clipboardNote!.FolderId,
      CreationDate: now,
      ModificationDate: now,
      Content: _clipboardNote!.Content,
      Status: true,
    );

    await db.child('Note').child(newNoteId.toString()).set(newNote.toJson());

    if (_isCutOperation) {
      await db
          .child('Note')
          .child(_clipboardNote!.Id.toString())
          .update({'Status': false});
    }

    _clipboardNote = null;
    _isCutOperation = false;
  }
}
