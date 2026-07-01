import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../ui_kerangka/theme_manager.dart';
import '../screens/login_screen.dart';

class SettingsAdminScreen extends StatelessWidget {
  const SettingsAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Admin'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Profil Section
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=68'), // Dummy admin photo
                ),
                const SizedBox(height: 16),
                const Text('Super Admin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                const Text('Administrator Sistem', style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () {
                    // TODO: Connect to backend
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Memuat data dari server... (Edit Profil)')),
                    );
                  },
                  child: const Text('Edit Profil Admin'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text('Preferensi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          
          // Dark Mode Toggle
          Card(
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: ThemeManager.themeModeNotifier,
              builder: (context, currentMode, child) {
                return SwitchListTile(
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode),
                  value: currentMode == ThemeMode.dark,
                  onChanged: (value) {
                    ThemeManager.toggleTheme(value);
                  },
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          const Text('Sistem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings_applications),
                  title: const Text('Pengaturan Aplikasi'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Memuat data dari server...')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Keamanan & Hak Akses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Memuat data dari server...')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal logout: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout (Keluar)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
