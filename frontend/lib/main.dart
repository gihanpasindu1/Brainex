import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/providers/locale_provider.dart';
import 'package:frontend/screens/splash_screen/splash_screen.dart';
import 'package:frontend/services/localization_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const _overlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, 
    statusBarBrightness: Brightness.dark, 
    systemNavigationBarColor: Colors.black, 
    systemNavigationBarIconBrightness: Brightness.light,
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: provider.locale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('si', ''),
            Locale('ta', ''),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: _overlayStyle,
              child: child ?? const SizedBox.shrink(),
            );
          },
          theme: ThemeData(
            appBarTheme: const AppBarTheme(systemOverlayStyle: _overlayStyle),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
