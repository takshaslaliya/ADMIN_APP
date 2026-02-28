import 'package:flutter/material.dart';
import 'package:splitease_test/core/theme/app_theme.dart';
import 'package:splitease_test/user/screens/tabs/dashboard_tab.dart';
import 'package:splitease_test/user/screens/tabs/groups_tab.dart';
import 'package:splitease_test/user/screens/tabs/add_group_tab.dart';
import 'package:splitease_test/user/screens/tabs/add_friends_tab.dart';
import 'package:splitease_test/user/screens/tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const GroupsTab(),
    const AddGroupTab(), // Placeholder, not used in Stack via index 2 directly
    const AddFriendsTab(),
    const SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex > 2
                ? _currentIndex
                : _currentIndex, // handle offset if needed, but we keep tabs length 5
            children: _tabs,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24, // Floating elevated
            child: _buildFloatingBottomNav(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBottomNav(bool isDark) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.lightSurface, // dark navy regardless of mode
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.lightSurfaceVariant, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.1),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(0, Icons.home_rounded, isDark),
            _buildNavItem(1, Icons.group_rounded, isDark),

            // Center Prominent + Button
            GestureDetector(
              onTap: () {
                setState(() => _currentIndex = 2);
              },
              child: Container(
                width: 56,
                height: 56,
                transform: Matrix4.translationValues(0.0, -10.0, 0.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      offset: const Offset(0, 6),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Color(0xFF0A1628), // dark navy icon on aqua button
                  size: 30,
                ),
              ),
            ),

            _buildNavItem(3, Icons.person_add_rounded, isDark),
            _buildNavItem(4, Icons.settings_rounded, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, bool isDark) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.darkSubtext;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
