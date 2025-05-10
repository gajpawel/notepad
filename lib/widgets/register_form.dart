import 'package:flutter/material.dart';

class RegisterForm extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const RegisterForm({
    Key? key,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: usernameController,
          decoration: const InputDecoration(
            labelText: 'Nazwa użytkownika',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value!.isEmpty) return 'Podaj nazwę użytkownika';
            if (value.length < 6) return 'Minimum 6 znaków';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value!.isEmpty) return 'Podaj email';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Niepoprawny email';
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
            if (value!.isEmpty) return 'Podaj hasło';
            if (value.length < 6) return 'Minimum 6 znaków';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Potwierdź hasło',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Potwierdź hasło' : null,
        ),
      ],
    );
  }
}
