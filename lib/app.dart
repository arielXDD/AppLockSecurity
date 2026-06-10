import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_style.dart';
import 'screens/calculator_screen.dart';
import 'screens/vault_screen.dart';

class BovedaApp extends StatefulWidget {
  const BovedaApp({super.key});

  @override
  State<BovedaApp> createState() => _BovedaAppState();
}

class _BovedaAppState extends State<BovedaApp> {
  final _appLinks = AppLinks();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    // Deep link si la app está cerrada
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _handleDeepLink(uri);
    } catch (_) {}

    // Deep link mientras la app está en segundo plano
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'boveda' && uri.host == 'open') {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool('access_deep_link') ?? true)) return;
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const VaultScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Calculadora',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: AppStyle.primary,
          secondary: const Color(0xFF9B8FFF),
          surface: AppStyle.bg,
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: AppStyle.bg,
        appBarTheme: AppBarTheme(
          backgroundColor: AppStyle.bg,
          elevation: 0,
          titleTextStyle: GoogleFonts.inter(
            color: AppStyle.text,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const CalculatorScreen(),
    );
  }
}
