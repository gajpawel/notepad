import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '/services/auth_service.dart';
import '/models/User.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Znajdź e-mail po loginie w Realtime Database
      String email = _emailController.text.trim();
      final snapshot =
          await FirebaseDatabase.instance.ref().child('Users').get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final data = child.value as Map;
          if (data['Login']?.toString().toLowerCase() == email.toLowerCase()) {
            email = data['Email']?.toString() ?? email;
            break;
          }
        }
      }

      final success = await AuthService.sendPasswordResetEmail(email);
      if (success && mounted) {
        Fluttertoast.showToast(
          msg: 'Wysłano e-mail z linkiem do resetowania hasła',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
          msg: 'Nie znaleziono użytkownika',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
      }
    } on auth.FirebaseAuthException catch (e) {
      String errorMessage = 'Wystąpił błąd';
      if (e.code == 'user-not-found') {
        errorMessage = 'Nie znaleziono użytkownika';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Nieprawidłowy format e-maila';
      }
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Wystąpił nieoczekiwany błąd',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resetowanie hasła')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Podaj e-mail lub nazwę użytkownika',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj e-mail lub nazwę użytkownika';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Kontynuuj'),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
