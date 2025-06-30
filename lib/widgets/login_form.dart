import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController loginController;
  final TextEditingController passwordController;

  const LoginForm({
    Key? key,
    required this.loginController,
    required this.passwordController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: loginController,
          decoration: const InputDecoration(
            labelText: 'Nazwa użytkownika',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Podaj nazwę użytkownika';
            }
            if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
              return 'Tylko litery i cyfry';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Hasło',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Podaj hasło';
            }
            return null;
          },
        ),
      ],
    );
  }
}
