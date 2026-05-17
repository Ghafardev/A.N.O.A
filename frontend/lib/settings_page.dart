import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.deepPurple[100],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader("Security"),
          SwitchListTile(
            title: const Text("Biometric Authentication"),
            subtitle: const Text("Use FaceID/Fingerprint to unlock"),
            value: true,
            onChanged: (bool value) {},
          ),
          SwitchListTile(
            title: const Text("Two-Factor Authentication"),
            value: false,
            onChanged: (bool value) {},
          ),
          const Divider(),
          _buildSectionHeader("Dashboard Preferences"),
          ListTile(
            title: const Text("Update Interval"),
            subtitle: const Text("Every 30 seconds"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: true,
            onChanged: (bool value) {},
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
