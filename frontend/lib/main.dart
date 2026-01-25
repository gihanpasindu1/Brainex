import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Force status bar + nav bar to be shown (NOT immersive)
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, // Android icons white
    statusBarBrightness: Brightness.dark, // iOS icons white
    systemNavigationBarColor: Colors.black, // safer visibility
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ Apply overlay style from the ROOT so every screen inherits it
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _overlayStyle,
          child: child ?? const SizedBox.shrink(),
        );
      },

      theme: ThemeData(
        // ✅ Also force overlay style for screens that use AppBar later
        appBarTheme: const AppBarTheme(systemOverlayStyle: _overlayStyle),
      ),

      home: Wrapper(),
    );
  }
}
