import 'package:intl/intl.dart';

class Folder {
  final int Id;
  final String Name;
  final String OwnerId;
  final int ParentFolderId;
  final DateTime CreationDate;
  final DateTime ModificationDate;
  final bool Status;


  Folder({
    required this.Id,
    required this.Name,
    required this.OwnerId,
    required this.ParentFolderId,
    required this.CreationDate,
    required this.ModificationDate,
    required this.Status,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? dateStr) {
      if (dateStr == null) return null;
      final trimmed = dateStr.trim();
      try {
        try {
          return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(trimmed);
        } catch (e) {
          return DateFormat('yyyy-MM-dd HH:mm:ss').parse(trimmed);
        }
      } catch (e) {
        print('Błąd parsowania daty w Folder: $trimmed - $e');
        return DateTime.now();
      }
    }

    return Folder(
      Id: json['Id'] as int? ?? 0,
      Name: json['Name'] as String? ?? '',
      OwnerId: json['OwnerId'] as String? ?? '',
      ParentFolderId: json['ParentFolderId'] as int? ?? 0,
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
      'ParentFolderId': ParentFolderId,
      'CreationDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(CreationDate),
      'ModificationDate': DateFormat('yyyy-MM-dd HH:mm:ss').format(ModificationDate),
      'Status': Status,
    };
  }
}
