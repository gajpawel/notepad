import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '/services/auth_service.dart';
import '/screens/home/home_screen.dart';
import '/widgets/login_form.dart';
import '/widgets/register_form.dart';
import 'forgot_screen.dart';
import '/models/User.dart';

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
  final TextEditingController _regEmailController = TextEditingController();
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
    _regEmailController.clear();
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
        if (!success) {
          throw auth.FirebaseAuthException(
            code: 'login-failed',
            message: 'Nieprawidłowa nazwa użytkownika lub hasło',
          );
        }
        if (mounted) _navigateToHomePage();
      } else {
        if (_passwordController.text != _confirmPasswordController.text) {
          throw auth.FirebaseAuthException(
            code: 'password-mismatch',
            message: 'Hasła nie są identyczne',
          );
        }
        success = await AuthService.register(
          _regLoginController.text.trim(),
          _regEmailController.text.trim(),
          _regNameController.text.trim(),
          _regSurnameController.text.trim(),
          _passwordController.text,
        );
        if (success) {
          Fluttertoast.showToast(
            msg: 'Rejestracja udana. Sprawdź e-mail, aby zweryfikować konto.',
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
          );
          _switchAuthMode(); // Przełącz na tryb logowania
        } else {
          throw auth.FirebaseAuthException(
            code: 'registration-failed',
            message: 'Rejestracja nieudana',
          );
        }
      }
    } on auth.FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'Nieprawidłowy format e-maila';
          break;
        case 'weak-password':
          errorMessage = 'Hasło jest za słabe';
          break;
        case 'email-already-in-use':
          errorMessage = 'E-mail jest już zajęty';
          break;
        case 'wrong-password':
          errorMessage = 'Nieprawidłowe hasło';
          break;
        case 'user-not-found':
          errorMessage = 'Nie znaleziono użytkownika';
          break;
        case 'user-mismatch':
          errorMessage = 'Błąd dopasowania użytkownika';
          break;
        case 'email-not-verified':
          errorMessage = 'Zweryfikuj swój adres e-mail przed zalogowaniem';
          break;
        case 'registration-failed':
        case 'login-failed':
        case 'password-mismatch':
          errorMessage = e.message ?? 'Wystąpił błąd';
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
                                emailController: _regEmailController,
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
    _regEmailController.dispose();
    _regNameController.dispose();
    _regSurnameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
