import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'ui/dashboard.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const AnoaApp(),
    ),
  );
}

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;
  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class LanguageProvider with ChangeNotifier {
  bool _isEnglish = true;
  bool get isEnglish => _isEnglish;

  Map<String, String> get labels => _isEnglish ? _en : _id;

  static const Map<String, String> _en = {
    'settings': 'Settings',
    'account': 'Security & Account',
    'language': 'Language',
    'theme': 'Appearance',
    'help': 'Help & Support',
    'help_content': 'ANOA System uses AI to analyze security threats. For more info, contact the Purple Team.',
  };

  static const Map<String, String> _id = {
    'settings': 'Pengaturan',
    'account': 'Keamanan & Akun',
    'language': 'Bahasa',
    'theme': 'Tampilan',
    'help': 'Bantuan & Dukungan',
    'help_content': 'ANOA System menggunakan AI untuk menganalisis ancaman keamanan. Untuk informasi lebih lanjut, hubungi Purple Team.',
  };

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }
}


class AnoaApp extends StatelessWidget {
  const AnoaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'ANOA System – Purple Team AI',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      // Tambahkan builder untuk global error handling UI
      builder: (context, child) {
        ErrorWidget.builder = (details) => _buildErrorCanvas(details);
        return child!;
      },
      home: const DashboardScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    final bg = isDark ? const Color(0xFF0A0E1A) : Colors.grey[50];
    final surface = isDark ? const Color(0xFF101626) : Colors.white;
    const primary = Color(0xFF6C63FF);
    const secondary = Color(0xFF00E5FF);

    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: const Color(0xFFF87171),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: isDark ? Colors.white : Colors.black87,
        displayColor: isDark ? Colors.white : Colors.black87,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1A2035) : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? const Color(0xFF283050) : Colors.grey[300]!, width: 1),
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

  Widget _buildErrorCanvas(FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: const Color(0xFF0A0E1A),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.gpp_maybe, color: Color(0xFFF87171), size: 64),
            const SizedBox(height: 16),
            Text("Security Sandbox Breach or UI Error", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
