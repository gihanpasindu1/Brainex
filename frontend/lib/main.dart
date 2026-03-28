import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/providers/locale_provider.dart';
import 'package:frontend/screens/activity_challenges/friend_challenge_entry_screen.dart';
import 'package:frontend/screens/splash_screen/splash_screen.dart';
import 'package:frontend/screens/wrapper.dart';
import 'package:frontend/services/localization_service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/create_profile/create_profile.dart';
import 'package:frontend/screens/activity_challenges/activity_challenges_screen.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => LocaleProvider())],
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
    return const _AppRoot();
  }
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSubscription;
  final AppLinks _appLinks = AppLinks();
  static const _overlayStyle = MyApp._overlayStyle;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (_) {}

    _linkSubscription = _appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme != 'brainex') return;

    String? challengeId;
    if (uri.host == 'challenge' && uri.pathSegments.isNotEmpty) {
      challengeId = uri.pathSegments.first;
    }

    if (challengeId == null || challengeId.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) return;

      navigator.push(
        MaterialPageRoute(
          builder: (_) => FriendChallengeEntryScreen(challengeId: challengeId!),
        ),
      );
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, provider, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
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
          routes: {
            '/profile': (context) => const CreateProfile(),
            '/activity-challenges': (context) =>
                const ActivityChallengesScreen(),
          },
          home:  Wrapper(),
        );
      },
    );
  }
}
