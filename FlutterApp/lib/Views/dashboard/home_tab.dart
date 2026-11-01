import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/Views/enquiries/send_enquiry_screen.dart';
import 'package:easy_rentals_mobile_app/Views/feedback_screen.dart';

/// The "Home" tab of [MainShell].
///
/// Presents four large action cards:
/// - Browse Property → switch to the Properties tab
/// - My Requests → switch to the Requests tab
/// - Send Inquiry → push [SendEnquiryScreen]
/// - Feedback → push [FeedbackScreen]
///
/// Tab switches are delegated to the parent via [onNavigateToTab] so this
/// widget remains unaware of [MainShell]'s indexing scheme.
class HomeTab extends StatelessWidget {
  /// Callback used to switch the parent's active tab by index.
  final Function(int) onNavigateToTab;

  const HomeTab({
    super.key,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    // Full-width scrolling column on the shared background colour.
    return Container(
      color: AppTheme.background,
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting / heading.
            const Text(
              'Welcome to Easy Rentals',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'What would you like to do today?',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Card 1: switch to the Properties tab (index 1).
            _buildActionCard(
              icon: Icons.home_outlined,
              title: 'Browse Property',
              accentColor: AppTheme.primaryPurple,
              onTap: () => onNavigateToTab(1),
            ),
            const SizedBox(height: 18),

            // Card 2: switch to the Requests tab (index 2).
            _buildActionCard(
              icon: Icons.calendar_month_outlined,
              title: 'My Requests',
              accentColor: AppTheme.brandGreen,
              onTap: () => onNavigateToTab(2),
            ),
            const SizedBox(height: 18),

            // Card 3: push the standalone enquiry screen.
            _buildActionCard(
              icon: Icons.chat_bubble_outline,
              title: 'Send Inquiry',
              accentColor: AppTheme.brandOrange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SendEnquiryScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            // Card 4: push the feedback screen.
            _buildActionCard(
              icon: Icons.star_outline,
              title: 'Feedback',
              accentColor: AppTheme.primaryPurple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FeedbackScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single tappable action card.
  ///
  /// [accentColor] tints the icon; the card body itself uses the shared card
  /// colour with a subtle border and soft shadow. InkWell provides the ripple
  /// effect and tap handling.
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.cardColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 145,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.borderColor,
              width: 1,
            ),
            boxShadow: [
              // Soft shadow giving the card a slight lift.
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            // Vertically centre the icon + label pair.
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: accentColor,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}