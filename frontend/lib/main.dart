import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// State Management untuk Bahasa
class LanguageProvider extends ChangeNotifier {
  bool _isEnglish = false;
  bool get isEnglish => _isEnglish;

  void toggleLanguage() {
    _isEnglish = !_isEnglish;
    notifyListeners();
  }

  // Kamus kata untuk sinkronisasi seluruh proyek
  Map<String, String> get labels => _isEnglish ? _en : _id;

  static const Map<String, String> _en = {
    'title': 'ANOA System Dashboard',
    'welcome': 'Welcome to ANOA Purple Team AI',
    'subtitle': 'Advanced Security Assistant with Gemini AI',
    'open_assistant': 'Open Assistant',
    'settings': 'Settings',
    'language': 'English Language',
    'theme': 'Dark Mode',
    'help': 'Documentation & Help',
    'help_content':
        'ANOA System is a Purple Team security assistant that integrates Gemini AI with Veea Lobster Trap DPI. Use the chat to analyze logs, code, or generate security rules.',
    'account': 'Account & Credentials',
    'login': 'Login',
    'username': 'Username',
    'password': 'Password',
  };

  static const Map<String, String> _id = {
    'title': 'Dashboard Sistem ANOA',
    'welcome': 'Selamat Datang di ANOA Purple Team AI',
    'subtitle': 'Asisten Keamanan Canggih dengan Gemini AI',
    'open_assistant': 'Buka Asisten',
    'settings': 'Pengaturan',
    'language': 'Bahasa Indonesia',
    'theme': 'Mode Gelap',
    'help': 'Dokumentasi & Bantuan',
    'help_content':
        'Sistem ANOA adalah asisten keamanan Purple Team yang mengintegrasikan Gemini AI dengan Veea Lobster Trap DPI. Gunakan chat untuk menganalisis log, kode, atau menghasilkan aturan keamanan.',
    'account': 'Akun & Kredensial',
    'login': 'Masuk',
    'username': 'Nama Pengguna',
    'password': 'Kata Sandi',
  };
}

// State Management untuk Tema
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'ANOA System',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _showChat = false;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(lang.labels['title']!),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield, size: 80, color: Color(0xFF6C63FF)),
                  const SizedBox(height: 20),
                  Text(
                    lang.labels['welcome']!,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lang.labels['subtitle']!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          if (_showChat)
            SizedBox(
              width: 400,
              child: ChatAssistant(
                onClose: () => setState(() => _showChat = false),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _showChat = !_showChat),
        tooltip: lang.labels['open_assistant'],
        child: Icon(_showChat ? Icons.close : Icons.smart_toy),
      ),
    );
  }
}

// Halaman Pengaturan Baru
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.labels['settings']!)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SEKSI: Tampilan & Bahasa
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(lang.labels['language']!),
                  secondary: const Icon(Icons.language),
                  value: lang.isEnglish,
                  onChanged: (_) => lang.toggleLanguage(),
                ),
                SwitchListTile(
                  title: Text(lang.labels['theme']!),
                  secondary: const Icon(Icons.brightness_6),
                  value: theme.isDarkMode,
                  onChanged: (_) => theme.toggleTheme(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // SEKSI: Akun
          Text(
            lang.labels['account']!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: lang.labels['username'],
                    ),
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: lang.labels['password'],
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text(lang.labels['login']!),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // SEKSI: Bantuan
          Text(
            lang.labels['help']!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(lang.labels['help_content']!),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatAssistant extends StatelessWidget {
  final VoidCallback onClose;

  const ChatAssistant({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        children: [
          AppBar(
            title: Text(lang.labels['open_assistant']!),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(icon: const Icon(Icons.close), onPressed: onClose),
            ],
          ),
          const Expanded(
            child: Center(child: Text("Chat Interface Placeholder")),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Type a message...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
