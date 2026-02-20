// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'pages/notes_page.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkTheme') ?? false;
  final languageCode = prefs.getString('languageCode') ?? 'ru';
  runApp(MyApp(
    initialDark: isDark,
    initialLocale: Locale(languageCode),
  ));
}

class MyApp extends StatefulWidget {
  final bool initialDark;
  final Locale initialLocale;
  const MyApp({
    super.key,
    required this.initialDark,
    required this.initialLocale,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDark;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _isDark = widget.initialDark;
    _locale = widget.initialLocale;
    Intl.defaultLocale = _locale.languageCode;
  }

  void _toggleTheme(bool dark) async {
    setState(() => _isDark = dark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkTheme', dark);
  }

  void _changeLanguage(Locale locale) async {
    setState(() {
      _locale = locale;
      Intl.defaultLocale = locale.languageCode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes Demo',
      theme: _isDark ? ThemeData.dark() : ThemeData.light(),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', ''),
        Locale('en', ''),
        Locale('uk', ''),
        Locale('de', ''),
      ],
      home: NotesPage(
        onThemeChanged: _toggleTheme,
        onLanguageChanged: _changeLanguage,
        currentLocale: _locale,
      ),
    );
  }
}
