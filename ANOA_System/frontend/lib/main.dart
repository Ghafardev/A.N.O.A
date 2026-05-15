import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui/dashboard.dart';

void main() {
  runApp(const AnoaApp());
}

class AnoaApp extends StatelessWidget {
  const AnoaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ANOA System – Purple Team AI',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const DashboardScreen(),
    );
  }

  ThemeData _buildTheme() {
    const bg = Color(0xFF0A0E1A);
    const surface = Color(0xFF101626);
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF00E5FF);

    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        tertiary: Color(0xFF34D399),
        error: Color(0xFFF87171),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A2035),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF283050), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF283050)),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1117),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF283050)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF283050)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: Colors.white38),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
