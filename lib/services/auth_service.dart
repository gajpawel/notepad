import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import '/models/User.dart';

class AuthService {
  static final _db = FirebaseDatabase.instance.ref().child('Users');
  static final _auth = auth.FirebaseAuth.instance;
  static User? _currentUser;

  static Future<bool> register(
    String login,
    String email,
    String name,
    String surname,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        throw auth.FirebaseAuthException(
          code: 'registration-failed',
          message: 'Nie udało się utworzyć użytkownika',
        );
      }

      // Zapis danych w Realtime Database
      final newUser = User(
        Uid: uid,
        Login: login,
        Email: email,
        Name: name,
        Surname: surname,
        Status: true,
        Theme: true,
      );
      await _db.child(uid).set(newUser.toJson());
      _currentUser = newUser;
      await credential.user?.sendEmailVerification();
      // Wylogowanie po rejestracji, aby wymusić weryfikację e-mail
      await _auth.signOut();
      _currentUser = null;
      return true;
    } on auth.FirebaseAuthException catch (e) {
      print('Błąd rejestracji: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Nieoczekiwany błąd rejestracji: $e');
      throw auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'Wystąpił nieoczekiwany błąd podczas rejestracji',
      );
    }
  }

  static Future<bool> login(String login, String password) async {
    try {
      // Znajdź e-mail po loginie w Realtime Database
      final snapshot = await _db.get();
      String? email;
      String? uid;
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = child.value as Map;
          if (data['Login']?.toString().toLowerCase() == login.toLowerCase()) {
            email = data['Email']?.toString();
            uid = data['Uid']?.toString();
            break;
          }
        }
      }

      if (email == null || uid == null) {
        throw auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'Nie znaleziono użytkownika',
        );
      }

      // Logowanie za pomocą e-maila i hasła
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user?.uid != uid) {
        throw auth.FirebaseAuthException(
          code: 'user-mismatch',
          message: 'Błąd dopasowania użytkownika',
        );
      }

      // Sprawdzenie weryfikacji e-mail
      if (!credential.user!.emailVerified) {
        await _auth.signOut();
        throw auth.FirebaseAuthException(
          code: 'email-not-verified',
          message: 'Zweryfikuj swój adres e-mail przed zalogowaniem',
        );
      }

      // Odczyt danych użytkownika
      final userSnapshot = await _db.child(uid).get();
      if (userSnapshot.exists) {
        _currentUser = User.fromJson(
          Map<String, dynamic>.from(userSnapshot.value as Map),
        );
        return true;
      }

      // Tworzenie minimalnego rekordu
      final newUser = User(
        Uid: uid,
        Login: login,
        Email: email,
        Name: '',
        Surname: '',
        Status: true,
        Theme: true,
      );
      await _db.child(uid).set(newUser.toJson());
      _currentUser = newUser;
      return true;
    } on auth.FirebaseAuthException catch (e) {
      print('Błąd logowania: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Nieoczekiwany błąd logowania: $e');
      throw auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'Wystąpił nieoczekiwany błąd podczas logowania',
      );
    }
  }

  static Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
  }

  static Future<User?> getCurrentUser() async {
    final authUser = _auth.currentUser;
    if (authUser == null || !authUser.emailVerified) return null;

    final snapshot = await _db.child(authUser.uid).get();
    if (snapshot.exists) {
      _currentUser = User.fromJson(
        Map<String, dynamic>.from(snapshot.value as Map),
      );
      return _currentUser;
    }
    return null;
  }

  static Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on auth.FirebaseAuthException catch (e) {
      print('Błąd wysyłania e-maila resetującego: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Nieoczekiwany błąd wysyłania e-maila: $e');
      throw auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'Wystąpił nieoczekiwany błąd podczas wysyłania e-maila',
      );
    }
  }

  static Future<bool> resetPasswordWithCode(
    String oobCode,
    String newPassword,
  ) async {
    try {
      await _auth.confirmPasswordReset(code: oobCode, newPassword: newPassword);
      return true;
    } on auth.FirebaseAuthException catch (e) {
      print('Błąd resetowania hasła: ${e.code} - ${e.message}');
      throw e;
    } catch (e) {
      print('Nieoczekiwany błąd resetowania hasła: $e');
      throw auth.FirebaseAuthException(
        code: 'unknown-error',
        message: 'Wystąpił nieoczekiwany błąd podczas resetowania hasła',
      );
    }
  }
}
