import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'currentUser';

  static Future<bool> register(
    String username,
    String email,
    String password,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    List<User> users = await getUsers();

    if (users.any((user) => user.username == username)) {
      return false;
    }
    if (users.any((user) => user.email == email)) {
      return false;
    }

    users.add(User(username: username, email: email, password: password));
    List<String> usersJson =
        users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList(_usersKey, usersJson);
    return true;
  }

  static Future<bool> login(String login, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<User> users = await getUsers();

    for (var user in users) {
      if ((user.username == login || user.email == login) &&
          user.password == password) {
        await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
        return true;
      }
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(_currentUserKey);
    return userJson != null ? User.fromJson(jsonDecode(userJson)) : null;
  }

  static Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? usersJson = prefs.getStringList(_usersKey);
    return usersJson
            ?.map((userJson) => User.fromJson(jsonDecode(userJson)))
            .toList() ??
        [];
  }

  static Future<User?> findUserByUsernameOrEmail(String login) async {
    List<User> users = await getUsers();
    for (var user in users) {
      if (user.username == login || user.email == login) {
        return user;
      }
    }
    return null;
  }

  static Future<void> updatePassword(User user, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    List<User> users = await getUsers();

    int index = users.indexWhere((u) => u.username == user.username);
    if (index != -1) {
      users[index] = User(
        username: user.username,
        email: user.email,
        password: newPassword,
      );

      List<String> usersJson =
          users.map((u) => jsonEncode(u.toJson())).toList();
      await prefs.setStringList(_usersKey, usersJson);

      User? currentUser = await getCurrentUser();
      if (currentUser != null && currentUser.username == user.username) {
        await prefs.setString(
          _currentUserKey,
          jsonEncode(users[index].toJson()),
        );
      }
    }
  }
}
