import 'package:flutter/material.dart';

class RegisterForm extends StatelessWidget {
  final TextEditingController loginController;
  final TextEditingController nameController;
  final TextEditingController surnameController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const RegisterForm({
    Key? key,
    required this.loginController,
    required this.nameController,
    required this.surnameController,
    required this.passwordController,
    required this.confirmPasswordController,
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
            if (value!.isEmpty) return 'Podaj nazwę użytkownika';
            if (value.length < 6) return 'Minimum 6 znaków';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Imię',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value!.isEmpty) return 'Podaj imię';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: surnameController,
          decoration: const InputDecoration(
            labelText: 'Nazwisko',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value!.isEmpty) return 'Podaj nazwisko';
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
