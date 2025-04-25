import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Noteable App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthPage(),
    );
  }
}

class User {
  final String username;
  final String email;
  final String password;

  User({required this.username, required this.email, required this.password});

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'password': password,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      email: json['email'] ?? '',
      password: json['password'],
    );
  }
}

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'currentUser';

  static Future<bool> register(String username, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<User> users = await getUsers();

    if (users.any((user) => user.username == username)) {
      return false;
    }
    if (users.any((user) => user.email == email)) {
      return false;
    }

    users.add(User(username: username, email: email, password: password));
    List<String> usersJson = users.map((user) => jsonEncode(user.toJson())).toList();
    await prefs.setStringList(_usersKey, usersJson);
    return true;
  }

  static Future<bool> login(String login, String password) async {
    final prefs = await SharedPreferences.getInstance();
    List<User> users = await getUsers();

    for (var user in users) {
      if ((user.username == login || user.email == login) && user.password == password) {
        await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
        return true;
      }
    }
    return false;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(_currentUserKey);
    return userJson != null ? User.fromJson(jsonDecode(userJson)) : null;
  }

  static Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? usersJson = prefs.getStringList(_usersKey);
    return usersJson?.map((userJson) => User.fromJson(jsonDecode(userJson))).toList() ?? [];
  }

  static Future<User?> findUserByUsernameOrEmail(String login) async {
    List<User> users = await getUsers();
    for (var user in users) {
      if (user.username == login || user.email == login) {
        return user;
      }
    }
    return null;
  }

  static Future<void> updatePassword(User user, String newPassword) async {
    final prefs = await SharedPreferences.getInstance();
    List<User> users = await getUsers();

    int index = users.indexWhere((u) => u.username == user.username);
    if (index != -1) {
      users[index] = User(
        username: user.username,
        email: user.email,
        password: newPassword,
      );

      List<String> usersJson = users.map((u) => jsonEncode(u.toJson())).toList();
      await prefs.setStringList(_usersKey, usersJson);

      User? currentUser = await getCurrentUser();
      if (currentUser != null && currentUser.username == user.username) {
        await prefs.setString(_currentUserKey, jsonEncode(users[index].toJson()));
      }
    }
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _regUsernameController = TextEditingController();
  final TextEditingController _regEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
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
    _regUsernameController.clear();
    _regEmailController.clear();
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
          _regUsernameController.text.trim(),
          _regEmailController.text.trim(),
          _passwordController.text,
        );
        if (success) await AuthService.login(_regEmailController.text.trim(), _passwordController.text);
      }

      if (!success) {
        setState(() {
          _errorMessage = isLogin
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
      MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Noteable')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Logowanie' : 'Rejestracja'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
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
                    if (isLogin) _buildLoginFields(),
                    if (!isLogin) _buildRegisterFields(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        backgroundColor: Theme.of(context).colorScheme.primary,
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
                    if (isLogin) TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginFields() {
    return Column(
      children: [
        TextFormField(
          controller: _loginController,
          decoration: const InputDecoration(
            labelText: 'Login (nazwa użytkownika lub email)',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Podaj login' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _passwordController,
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

  Widget _buildRegisterFields() {
    return Column(
      children: [
        TextFormField(
          controller: _regUsernameController,
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
          controller: _regEmailController,
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
          controller: _passwordController,
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
          controller: _confirmPasswordController,
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

  @override
  void dispose() {
    _loginController.dispose();
    _regUsernameController.dispose();
    _regEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

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

    User? user = await AuthService.findUserByUsernameOrEmail(_loginController.text.trim());
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
        MaterialPageRoute(
          builder: (context) => ResetPasswordPage(user: user),
        ),
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
                labelText: 'Podaj nazwę użytkownika lub email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            if (_errorMessage != null)
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Kontynuuj'),
            ),
          ],
        ),
      ),
    );
  }
}

class ResetPasswordPage extends StatefulWidget {
  final User user;

  const ResetPasswordPage({super.key, required this.user});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submit() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Hasła nie są identyczne');
      return;
    }
    if (_newPasswordController.text.length < 6) {
      setState(() => _errorMessage = 'Minimum 6 znaków');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await AuthService.updatePassword(widget.user, _newPasswordController.text);

    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasło zostało zresetowane')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nowe hasło')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nowe hasło',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Potwierdź nowe hasło',
                border: OutlineInputBorder(),
              ),
            ),
            if (_errorMessage != null)
              Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Zresetuj hasło'),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    User? user = await AuthService.getCurrentUser();
    if (user != null && mounted) setState(() => _username = user.username);
  }

  void _newNote() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const NewNote()));
  }

  void _logout() async {
    await AuthService.logout();
    if (mounted) Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          if (_username != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(child: Text('Witaj, $_username')),
            ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
            tooltip: 'Wyloguj',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Zanotujemy coś?'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _newNote,
        tooltip: 'Nowa notatka',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NewNote extends StatelessWidget {
  const NewNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nowa notatka')),
      body: const Center(
        child: Text('Tutaj możesz dodać nową notatkę.'),
      ),
    );
  }
}