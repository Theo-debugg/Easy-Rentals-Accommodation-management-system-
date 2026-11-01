import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';

/// A styled bottom navigation bar used across the app's main tabs.
///
/// Wraps a [BottomNavigationBar] in a container that adds a top border and a
/// soft upward shadow, giving it a card-like appearance that separates it from
/// the scaffold background.
class CustomBottomNav extends StatelessWidget {
  /// Index of the currently selected tab.
  final int currentIndex;

  /// Callback invoked with the tapped tab's index when the user changes tabs.
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Outer container provides the visual chrome (border, shadow, white bg)
    // around the actual BottomNavigationBar.
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: const Border(
          top: BorderSide(
            color: AppTheme.borderColor,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        // Fixed layout keeps all labels visible regardless of item count.
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryPurple,
        unselectedItemColor: AppTheme.textSecondary,
        // Let the wrapping container supply background and elevation.
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
        ),
        items: [
          _buildItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
          ),
          _buildItem(
            icon: Icons.home_work_outlined,
            activeIcon: Icons.home_work,
            label: 'Properties',
          ),
          _buildItem(
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
            label: 'My Requests',
          ),
          _buildItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Messages',
          ),
          _buildItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  /// Builds a single navigation item with paired outline (inactive) and
  /// filled (active) icons.
  BottomNavigationBarItem _buildItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    return BottomNavigationBarItem(
      icon: Icon(icon),
      activeIcon: Icon(activeIcon),
      label: label,
    );
  }
}