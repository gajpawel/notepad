class User {
  final String Uid;
  final String Login;
  final String Email;
  final String Name;
  final String Surname;
  final bool Status;
  final bool Theme;

  User({
    required this.Uid,
    required this.Login,
    required this.Email,
    required this.Name,
    required this.Surname,
    this.Status = true,
    this.Theme = true,
  });

  Map<String, dynamic> toJson() => {
    'Uid': Uid,
    'Login': Login,
    'Email': Email,
    'Name': Name,
    'Surname': Surname,
    'Status': Status,
    'Theme': Theme,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      Uid: json['Uid'],
      Login: json['Login'],
      Email: json['Email'],
      Name: json['Name'] ?? '',
      Surname: json['Surname'] ?? '',
      Status: json['Status'] ?? true,
      Theme: json['Theme'] ?? true,
    );
  }
}
