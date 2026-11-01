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

/// The main post-login container: a shared app bar, a bottom nav bar, and an
/// [IndexedStack] of the five dashboard tabs.
///
/// Keeps the tab state alive across switches (via IndexedStack) and exposes a
/// static [goToTab] helper so any descendant screen can jump to a tab and pop
/// back to the shell in one call.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  /// Global key to the state, enabling the static [goToTab] helper to reach
  /// this shell's [MainShellState] from anywhere in the widget tree.
  static final GlobalKey<MainShellState> shellKey =
      GlobalKey<MainShellState>();

  /// Pops everything above the shell, then switches to the tab at [index].
  ///
  /// Used by screens like [BookingAppointmentScreen] and [SendEnquiryScreen]
  /// whose bottom nav can navigate into the shell.
  static void goToTab(BuildContext context, int index) {
    // First pop back to the shell so its state is guaranteed to be alive.
    Navigator.of(context).popUntil((route) => route.isFirst);
    shellKey.currentState?.setIndex(index);
  }

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  // Index of the currently visible tab.
  int _currentIndex = 0;

  // Used by the logout button in the app bar.
  final AuthViewModel _auth = AuthViewModel();

  /// The five tabs, in bottom-nav order.
  ///
  /// Rebuilt on each access so tab-level state (search text, controllers, etc.)
  /// persists across rebuilds thanks to the IndexedStack + Element reuse.
  List<Widget> get _tabs => [
        HomeTab(onNavigateToTab: setIndex),
        const PropertiesTab(),
        const RequestsTab(),
        const MessagesTab(),
        const ProfileTab(),
      ];

  /// Switches to [index] if it's in range and different from the current tab.
  void setIndex(int index) {
    // Guard against out-of-range indices from rogue callers.
    if (index < 0 || index > 4) return;

    if (mounted && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  /// Signs the user out, then replaces the entire navigation stack with the
  /// login screen so they can't navigate back into authenticated content.
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
        // Matches the background colour so M3's tint doesn't shade the bar.
        surfaceTintColor: AppTheme.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        titleSpacing: 16,
        title: Row(
          children: [
            // Logo tile with a soft purple backdrop.
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
                // Fallback icon if the asset can't be loaded.
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

            // App title + subtitle stack.
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

            // Logout action.
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

            // Profile shortcut: jumps straight to the Profile tab (index 4).
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

      // IndexedStack keeps all tabs mounted so their state survives switching.
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),

      // Shared bottom navigation; tapping a tab calls setIndex.
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: setIndex,
      ),
    );
  }
}