import 'package:flutter/material.dart';
import 'dashboard_admin_screen.dart';
import 'user_management_screen.dart';
import 'resolution_center_screen.dart';
import 'settings_admin_screen.dart';

class MainNavigationAdmin extends StatefulWidget {
  const MainNavigationAdmin({Key? key}) : super(key: key);

  @override
  State<MainNavigationAdmin> createState() => _MainNavigationAdminState();
}

class _MainNavigationAdminState extends State<MainNavigationAdmin> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardAdminScreen(),
    const UserManagementScreen(),
    const ResolutionCenterScreen(),
    const SettingsAdminScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Pengguna',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Transaksi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
