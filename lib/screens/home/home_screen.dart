import 'package:flutter/material.dart';
import '/services/auth_service.dart';
import '/models/user.dart';
import '/screens/login/auth_page.dart';
import '/widgets/drawer.dart';

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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewNote()),
    );
  }

  void _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    }
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
      drawer: AppDrawer(), // Dodano drawer
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[Text('Zanotujemy coś?')],
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
      body: const Center(child: Text('Tutaj możesz dodać nową notatkę.')),
    );
  }
}
