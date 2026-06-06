import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';

// ─── Konstanta Warna (Sync with Dashboard) ───────────────────────────────────
const kBg = Color(0xFF0A0E1A);
const kSurface = Color(0xFF101626);
const kCard = Color(0xFF1A2035);
const kBorder = Color(0xFF283050);
const kPrimary = Color(0xFF6C63FF);
const kCyan = Color(0xFF00E5FF);
const kText2 = Color(0xFF8892B0);
const kSuccess = Color(0xFF34D399);

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: Text(
          lang.labels['settings']!,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: kSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: kBorder, height: 1),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildSectionHeader(lang.labels['account']!, Icons.security_outlined),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: lang.labels['language']!,
                  subtitle: lang.isEnglish ? "Current: English" : "Saat ini: Indonesia",
                  icon: Icons.language_rounded,
                  value: lang.isEnglish,
                  onChanged: (bool value) => lang.toggleLanguage(),
                  activeColor: kCyan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader(lang.labels['theme']!, Icons.palette_outlined),
          _buildSettingsCard(
            child: Column(
              children: [
                _buildSwitchTile(
                  title: lang.labels['theme']!,
                  subtitle: theme.isDarkMode ? "Dark Mode Enabled" : "Light Mode Enabled",
                  icon: theme.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  value: theme.isDarkMode,
                  onChanged: (bool value) => theme.toggleTheme(),
                  activeColor: kPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSectionHeader(lang.labels['help']!, Icons.help_outline_rounded),
          _buildSettingsCard(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(
                lang.labels['help']!,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
              ),
              subtitle: Text(
                lang.labels['help_content']!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: kText2, fontSize: 12),
              ),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.info_outline, color: kPrimary, size: 20),
              ),
              trailing: const Icon(Icons.chevron_right, color: kText2),
              onTap: () {
                _showHelpDialog(context, lang);
              },
            ),
          ),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              'ANOA System v2.2.0\nPurple Team Security Assistant',
              textAlign: TextAlign.center,
              style: TextStyle(color: kText2.withValues(alpha: 0.5), fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: kCyan, size: 16),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kCyan,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: kText2, fontSize: 12),
      ),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: activeColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: activeColor, size: 20),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      activeTrackColor: activeColor.withValues(alpha: 0.3),
    );
  }

  void _showHelpDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: kBorder)),
        title: Text(lang.labels['help']!, style: const TextStyle(color: Colors.white)),
        content: Text(lang.labels['help_content']!, style: const TextStyle(color: kText2, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: kCyan, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
