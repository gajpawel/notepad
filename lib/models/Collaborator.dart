class Collaborator {
  final int Id;
  final String CollaboratorId;
  final int NoteId;

  Collaborator({
    required this.Id, 
    required this.CollaboratorId, 
    required this.NoteId
  });

  Map<String, dynamic> toJson() => {
    'Id': Id,
    'CollaboratorId': CollaboratorId,
    'NoteId': NoteId
  };

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      Id: json['Id'] ?? 0,
      CollaboratorId: (json['CollaboratorId'] ?? '').toString(),
      NoteId: json['NoteId'] ?? 0,
    );
  }
}