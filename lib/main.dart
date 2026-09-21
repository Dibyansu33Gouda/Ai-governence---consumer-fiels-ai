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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD600),
          secondary: Color(0xFFFFFFFF),
          surface: Color(0xFF141414),
          error: Color(0xFFFF3333),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A0A0A),
          foregroundColor: Color(0xFFFFD600),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFFFFD600), 
            fontSize: 26, 
            fontWeight: FontWeight.w900, 
            letterSpacing: -0.5
          ),
          iconTheme: IconThemeData(color: Color(0xFFFFD600)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD600),
            foregroundColor: const Color(0xFF000000),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2.0),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
        cardTheme: CardTheme(
          color: const Color(0xFF141414),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.0),
            side: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
