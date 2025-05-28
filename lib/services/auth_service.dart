import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  static final _db = FirebaseDatabase.instance.ref().child('Users');

  static User? _currentUser;

  static Future<bool> register(String Login,
      String Name,
      String Surname,
      String Password,) async {
    final snapshot = await _db.get();

    for (var child in snapshot.children) {
      final data = child.value as Map;
      if (data['Login'] == Login) {
        return false;
      }
    }

    final newUser = User(Login: Login,
        Name: Name,
        Surname: Surname,
        Password: Password,
        Status: true,
        Theme: true);
    final userMap = newUser.toJson();
    await _db.child(userMap['Login']!).set(userMap);
    return true;
  }


  static Future<bool> login(String login, String password) async {
    DataSnapshot snapshot = await _db.get();

    if (snapshot.exists && snapshot.value is Map) {
      final usersMap = Map<String, dynamic>.from(snapshot.value as Map);

      for (var userData in usersMap.values) {
        if (userData is Map &&
            userData['Login'] == login &&
            userData['Password'] == password) {
          _currentUser = User.fromJson(Map<String, dynamic>.from(userData));
          return true;
        }
      }
    }

    return false;
  }


  static Future<void> logout() async {
    _currentUser = null;
  }

  static Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  static Future<List<User>> getUsers() async {
    final snapshot = await _db.get();
    if (!snapshot.exists) return [];

    return snapshot.children
        .map((child) =>
        User.fromJson(Map<String, dynamic>.from(child.value as Map)))
        .toList();
  }


  static Future<User?> findUserByLogin(String login) async {
    final users = await getUsers();
    for (var user in users) {
      if (user.Login == login) {
        return user;
      }
    }
    return null;
  }


  static Future<bool> updatePassword(String login, String newPassword) async {
    final userRef = _db.child(login);

    final snapshot = await userRef.get();
    if (!snapshot.exists) return false;

    final userData = snapshot.value as Map?;
    if (userData == null) return false;

    userData['Password'] = newPassword;
    await userRef.set(userData); // nadpisuje dane

    if (_currentUser?.Login == login) {
      _currentUser = User.fromJson(Map<String, dynamic>.from(userData));
    }

    return true;
  }

}