import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.labels['settings']!),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(lang.labels['account']!),
          SwitchListTile(
            title: Text(lang.labels['language']!),
            subtitle: Text(lang.isEnglish ? "Switch to Indonesia" : "Ganti ke Inggris"),
            secondary: const Icon(Icons.language),
            value: lang.isEnglish,
            onChanged: (bool value) => lang.toggleLanguage(),
          ),
          const Divider(),
          _buildSectionHeader(lang.labels['theme']!),
          SwitchListTile(
            title: Text(lang.labels['theme']!),
            secondary: Icon(theme.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            value: theme.isDarkMode,
            onChanged: (bool value) => theme.toggleTheme(),
          ),
          const Divider(),
          _buildSectionHeader(lang.labels['help']!),
          ListTile(
            title: Text(lang.labels['help']!),
            subtitle: Text(lang.labels['help_content']!, maxLines: 2, overflow: TextOverflow.ellipsis),
            leading: const Icon(Icons.help_outline),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(lang.labels['help']!),
                  content: Text(lang.labels['help_content']!),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}
