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
            labelText: 'Login (nazwa użytkownika)',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Podaj login' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Hasło',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Podaj hasło' : null,
        ),
      ],
    );
  }
}
