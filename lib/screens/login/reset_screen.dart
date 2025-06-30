import 'package:Noteable/screens/login/auth_page.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '/services/auth_service.dart';
import '/screens/home/home_screen.dart';

class ResetPasswordPage extends StatefulWidget {
  final String oobCode;

  const ResetPasswordPage({super.key, required this.oobCode});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final success = await AuthService.resetPasswordWithCode(
        widget.oobCode,
        _newPasswordController.text,
      );
      if (success && mounted) {
        Fluttertoast.showToast(
          msg: 'Hasło zostało zresetowane. Zaloguj się.',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthPage()),
        );
      } else {
        setState(() {
          _errorMessage = 'Nie udało się zresetować hasła';
          _isLoading = false;
        });
      }
    } on auth.FirebaseAuthException catch (e) {
      String errorMessage = 'Wystąpił błąd';
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Nowe hasło jest za słabe';
          break;
        case 'expired-action-code':
          errorMessage = 'Link resetowania hasła wygasł';
          break;
        case 'invalid-action-code':
          errorMessage = 'Nieprawidłowy link resetowania hasła';
          break;
        default:
          errorMessage = 'Wystąpił nieoczekiwany błąd: ${e.message}';
      }
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: errorMessage,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Wystąpił nieoczekiwany błąd';
        _isLoading = false;
      });
      Fluttertoast.showToast(
        msg: 'Wystąpił nieoczekiwany błąd',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nowe hasło')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nowe hasło',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Podaj nowe hasło';
                  }
                  if (value.length < 6) {
                    return 'Minimum 6 znaków';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Potwierdź nowe hasło',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Potwierdź hasło';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Hasła nie są identyczne';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Zresetuj hasło'),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
