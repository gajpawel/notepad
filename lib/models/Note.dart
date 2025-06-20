class Note {
  final int Id;
  final String Name;
  final String CreationDate;
  final String ModificationDate;
  final String OwnerId;
  final int? FolderId; // Nullable field
  final bool Status;
  final String Content;

  Note({
    required this.Id,
    required this.Name,
    required this.CreationDate,
    required this.ModificationDate,
    required this.OwnerId,
    this.FolderId, // Nullable - może być null
    required this.Status,
    required this.Content,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      Id: _safeParseInt(json['Id']),
      Name: json['Name']?.toString() ?? '',
      CreationDate: json['CreationDate']?.toString() ?? '',
      ModificationDate: json['ModificationDate']?.toString() ?? '',
      OwnerId: json['OwnerId']?.toString() ?? '',
      FolderId: _safeParseIntNullable(json['FolderId']), // Bezpieczne parsowanie nullable int
      Status: _safeParseBool(json['Status']),
      Content: json['Content']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': Id,
      'Name': Name,
      'CreationDate': CreationDate,
      'ModificationDate': ModificationDate,
      'OwnerId': OwnerId,
      'FolderId': FolderId,
      'Status': Status,
      'Content': Content,
    };
  }

  // Pomocnicze funkcje do bezpiecznego parsowania
  static int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  static int? _safeParseIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  static bool _safeParseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return false;
  }
}