import 'package:flutter/material.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/services/localization_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthServices _auth = AuthServices();

  Future<void> _logout() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final tr = AppLocalizations.of(context);
    String t(String key) => tr?.translate(key) ?? key;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('home')),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: Text(t('home'), style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
