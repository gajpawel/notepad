class Note {
  final int Id;
  final String Name;
  final String OwnerId;
  final String CreationDate;
  final String ModificationDate;
  final int? FolderId;
  final bool Status;
  final String Content;

  Note({required this.Id, required this.Name, required this.OwnerId, required this.FolderId, required this.CreationDate, required this.ModificationDate, this.Content="", this.Status=true});

  Map<String, dynamic> toJson() => {
    'Id': Id,
    'Name': Name,
    'OwnerId': OwnerId,
    'CreationDate': CreationDate,
    'ModificationDate': ModificationDate,
    'ParentFolderId' : FolderId,
    'Status': Status,
    'Content': Content
  };

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
        Id: json['Id'],
        Name: json['Name'],
        OwnerId: json['OwnerId'].toString() ?? '',
        CreationDate: json['CreationDate'] ?? '',
        ModificationDate: json['ModificationDate'],
        FolderId: json['FolderId'],
        Status: json['Status'],
        Content: json['Content']
    );
  }
}
