class User {
  final String username;
  final String email;
  final String password;

  User({required this.username, required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      email: json['email'] ?? '',
      password: json['password'],
    );
  }
}
