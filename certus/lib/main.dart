import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'modules/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Warning: .env file not found.");
  }
  runApp(const CertusApp());
}

class CertusApp extends StatelessWidget {
  const CertusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Certus',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9F9F7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2C3E50),
          secondary: Color(0xFFE67E22),
          surface: Colors.white,
          error: Color(0xFFC0392B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C3E50),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C3E50),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
          ),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
          ),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
