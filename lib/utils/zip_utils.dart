import 'dart:typed_data';
import 'package:archive/archive.dart';
import '../models/Note.dart';
import '../models/Folder.dart';

Uint8List createZipInMemory(Folder folder, List<Note> notes) {
  final archive = Archive();

  for (final note in notes) {
    final filename = '${note.Name}.txt';
    final content = note.Content;
    archive.addFile(ArchiveFile(filename, content.length, content.codeUnits));
  }

  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}
