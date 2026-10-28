import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/ViewModels/auth_view_model.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_bottom_nav.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/home_tab.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/properties_tab.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/requests_tab.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/messages_tab.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/profile_tab.dart';
import 'package:easy_rentals_mobile_app/Views/authentication/login_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static final GlobalKey<MainShellState> shellKey =
      GlobalKey<MainShellState>();

  static void goToTab(BuildContext context, int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    shellKey.currentState?.setIndex(index);
  }

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final AuthViewModel _auth = AuthViewModel();

  List<Widget> get _tabs => [
        HomeTab(onNavigateToTab: setIndex),
        const PropertiesTab(),
        const RequestsTab(),
        const MessagesTab(),
        const ProfileTab(),
      ];

  void setIndex(int index) {
    if (index < 0 || index > 4) return;

    if (mounted && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  Future<void> _handleLogout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        backgroundColor: AppTheme.white,
        surfaceTintColor: AppTheme.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.primaryPurple.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/easy-rentals-group-logo.webp',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.home_work_outlined,
                    color: AppTheme.primaryPurple,
                    size: 28,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),

            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Easy Rentals',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Student Accommodation',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),

            IconButton(
              tooltip: 'Logout',
              onPressed: _handleLogout,
              icon: const Icon(
                Icons.logout_outlined,
                color: AppTheme.textSecondary,
              ),
            ),

            /*IconButton(
              tooltip: 'Notifications',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications are not available yet.'),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none,
                color: AppTheme.textSecondary,
              ),
            ),*/

            IconButton(
              tooltip: 'Profile',
              onPressed: () => setIndex(4),
              icon: const Icon(
                Icons.person_outline,
                color: AppTheme.primaryPurple,
              ),
            ),
          ],
        ),
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),

      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: setIndex,
      ),
    );
  }
}