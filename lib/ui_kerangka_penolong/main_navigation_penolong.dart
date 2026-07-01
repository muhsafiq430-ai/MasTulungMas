import 'package:flutter/material.dart';
import '../ui_kerangka/app_theme.dart';
import 'dashboard_penolong_screen.dart';
import 'job_market_screen.dart';
import 'riwayat_penolong_screen.dart';
import 'settings_penolong_screen.dart';

class MainNavigationPenolong extends StatefulWidget {
  const MainNavigationPenolong({Key? key}) : super(key: key);

  @override
  State<MainNavigationPenolong> createState() => _MainNavigationPenolongState();
}

class _MainNavigationPenolongState extends State<MainNavigationPenolong> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardPenolongScreen(),
    const JobMarketScreen(),
    const RiwayatPenolongScreen(),
    const SettingsPenolongScreen(),
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
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_outline),
              activeIcon: Icon(Icons.work),
              label: 'Job Market',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Riwayat',
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
