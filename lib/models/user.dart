class User {
  final String Login;
  final String Name;
  final String Surname;
  final String Password;
  final bool Status;
  final bool Theme;

  User({required this.Login, required this.Name, required this.Surname, required this.Password, this.Status=true, this.Theme=true});

  Map<String, dynamic> toJson() => {
    'Login': Login,
    'Name': Name,
    'Surname': Surname,
    'Password': Password,
    'Status' : Status,
    'Theme' : Theme
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      Login: json['Login'],
      Name: json['Name'] ?? '',
      Surname: json['Surname'] ?? '',
      Password: json['Password'],
      Status: json['Status'],
      Theme: json['Theme']
    );
  }
}
