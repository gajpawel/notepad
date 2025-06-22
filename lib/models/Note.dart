import 'package:intl/intl.dart';

class Note {
  final int Id;
  final String Name;
  final String OwnerId;
  final String Content;
  final int FolderId;
  final DateTime CreationDate;
  final DateTime ModificationDate;
  final bool Status;

  Note({
    required this.Id,
    required this.Name,
    required this.OwnerId,
    required this.Content,
    required this.FolderId,
    required this.CreationDate,
    required this.ModificationDate,
    required this.Status,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      final trimmed = dateStr.trim();
      try {
        try {
          return DateFormat('yyyy-MM-ddTHH:mm:ss').parse(trimmed);
        } catch (e) {
          return DateFormat('yyyy-MM-dd HH:mm:ss').parse(trimmed);
        }
      } catch (e) {
        print('Błąd parsowania daty w Note: $trimmed - $e');
        return DateTime.now();
      }
    }

    return Note(
      Id: json['Id'] as int? ?? 0,
      Name: json['Name'] as String? ?? '',
      Content: json['Content'] as String? ?? '',
      OwnerId: (json['OwnerId']?.toString() ?? ''),
      FolderId: json['FolderId'] as int? ?? 0,
      CreationDate: parseDate(json['CreationDate'] as String?) ?? DateTime.now(),
      ModificationDate: parseDate(json['ModificationDate'] as String?) ?? DateTime.now(),
      Status: json['Status'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': Id,
      'Name': Name,
      'OwnerId': OwnerId,
      'Content': Content,
      'FolderId': FolderId,
      'CreationDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(CreationDate),
      'ModificationDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(ModificationDate),
      'Status': Status,
    };
  }
}
