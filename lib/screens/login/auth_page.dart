import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../home/home_screen.dart';
import 'forgot_screen.dart';
import '../../widgets/login_form.dart';
import '../../widgets/register_form.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _regLoginController = TextEditingController();
  final TextEditingController _regNameController = TextEditingController();
  final TextEditingController _regSurnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    setState(() => _isLoading = true);
    User? currentUser = await AuthService.getCurrentUser();
    if (currentUser != null && mounted) _navigateToHomePage();
    if (mounted) setState(() => _isLoading = false);
  }

  void _switchAuthMode() {
    _loginController.clear();
    _regLoginController.clear();
    _regNameController.clear();
    _regSurnameController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    setState(() {
      isLogin = !isLogin;
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success;
      if (isLogin) {
        success = await AuthService.login(
          _loginController.text.trim(),
          _passwordController.text,
        );
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          setState(() {
            _errorMessage = 'Hasła nie są identyczne';
            _isLoading = false;
          });
          return;
        }
        success = await AuthService.register(
          _regLoginController.text.trim(),
          _regNameController.text.trim(),
          _regSurnameController.text.trim(),
          _passwordController.text,
        );
        if (success)
          await AuthService.login(
            _regNameController.text.trim(),
            _passwordController.text,
          );
      }

      if (!success) {
        setState(() {
          _errorMessage =
              isLogin
                  ? 'Nieprawidłowy login lub hasło'
                  : 'Użytkownik lub email już istnieje';
          _isLoading = false;
        });
        return;
      }

      if (mounted) _navigateToHomePage();
    } catch (e) {
      setState(() {
        _errorMessage = 'Wystąpił błąd';
        _isLoading = false;
      });
    }
  }

  void _navigateToHomePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyHomePage(title: 'Noteable'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Logowanie' : 'Rejestracja'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isLogin)
                              LoginForm(
                                loginController: _loginController,
                                passwordController: _passwordController,
                              ),
                            if (!isLogin)
                              RegisterForm(
                                loginController: _regLoginController,
                                nameController: _regNameController,
                                surnameController: _regSurnameController,
                                passwordController: _passwordController,
                                confirmPasswordController:
                                    _confirmPasswordController,
                              ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              child: Text(
                                isLogin ? 'ZALOGUJ' : 'ZAREJESTRUJ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (isLogin)
                              TextButton(
                                onPressed:
                                    () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                const ForgotPasswordPage(),
                                      ),
                                    ),
                                child: const Text('Zapomniałeś hasła?'),
                              ),
                            TextButton(
                              onPressed: _switchAuthMode,
                              child: Text(
                                isLogin
                                    ? 'Nie masz konta? Zarejestruj się'
                                    : 'Masz już konto? Zaloguj się',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _navigateToHomePage,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                backgroundColor: Colors.green,
                              ),
                              child: const Text(
                                'PRZEJDŹ DO STRONY GŁÓWNEJ (DEBUG)',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _loginController.dispose();
    _regLoginController.dispose();
    _regNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
