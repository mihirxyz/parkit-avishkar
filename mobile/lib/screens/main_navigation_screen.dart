import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'home_dashboard_screen.dart';
import 'zone_map_screen.dart';

/// Root navigation shell with smooth tab switching.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _switchToTab(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(onOpenMap: () => _switchToTab(1)),
      const ZoneMapScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.surfaceBorder, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: [
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                isActive: _currentIndex == 0,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: _AnimatedNavIcon(
                icon: Icons.map_outlined,
                activeIcon: Icons.map_rounded,
                isActive: _currentIndex == 1,
              ),
              label: 'Zone Map',
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated navigation icon with bounce effect on selection.
class _AnimatedNavIcon extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;

  const _AnimatedNavIcon({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isActive ? 1.18 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: Icon(isActive ? activeIcon : icon),
    );
  }
}
