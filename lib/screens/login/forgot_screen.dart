import 'package:flutter/material.dart';
import '/services/auth_service.dart';
import '/models/User.dart';
import 'reset_screen.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _loginController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    User? user = await AuthService.findUserByLogin(
      _loginController.text.trim(),
    );
    if (user == null) {
      setState(() {
        _errorMessage = 'Nie znaleziono użytkownika';
        _isLoading = false;
      });
      return;
    }
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ResetPasswordPage(user: user)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resetowanie hasła')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _loginController,
              decoration: const InputDecoration(
                labelText: 'Podaj nazwę użytkownika',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Kontynuuj'),
            ),
          ],
        ),
      ),
    );
  }
}
