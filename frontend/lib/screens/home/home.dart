import 'package:flutter/material.dart';
import 'package:frontend/services/auth.dart';
import 'package:frontend/services/lang_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthServices _auth = AuthServices();

  bool _loadingLang = true;

  @override
  void initState() {
    super.initState();
    _initLang();
  }

  Future<void> _initLang() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('selected_language') ?? 'en';

    await LangService.instance.load(code);

    if (!mounted) return;
    setState(() => _loadingLang = false);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('selected_language');
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLang) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final t = LangService.instance;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.t('home')),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Center(
        child: Text(t.t('home'), style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}
