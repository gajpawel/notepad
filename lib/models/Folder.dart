class Folder {
  final int Id;
  final String Name;
  final String OwnerId;
  final String CreationDate;
  final String ModificationDate;
  final int? ParentFolderId;
  final bool Status;

  Folder({required this.Id, required this.Name, required this.OwnerId, required this.ParentFolderId, required this.CreationDate, required this.ModificationDate, this.Status = true});

  Map<String, dynamic> toJson() => {
    'Id': Id,
    'Name': Name,
    'OwnerId': OwnerId,
    'CreationDate': CreationDate,
    'ModificationDate': ModificationDate,
    'ParentFolderId' : ParentFolderId,
    'Status' : Status
  };

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
        Id: json['Id'],
        Name: json['Name'],
        OwnerId: json['OwnerId'].toString(),
        CreationDate: json['CreationDate'],
        ModificationDate: json['ModificationDate'],
        ParentFolderId: json['ParentFolderId'] ?? null,
        Status: json['Status']
    );
  }
}
