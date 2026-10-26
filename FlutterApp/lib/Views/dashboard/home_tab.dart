import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/Views/enquiries/send_enquiry_screen.dart';
import 'package:easy_rentals_mobile_app/Views/feedback_screen.dart';

class HomeTab extends StatelessWidget {
  final Function(int) onNavigateToTab;

  const HomeTab({
    super.key,
    required this.onNavigateToTab,
  });

  static const Color primaryBlue = Color(0xFF2459A9);
  static const Color backgroundColor = Color(0xFFF7F9FC);
  static const Color textColor = Color(0xFF202A38);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      width: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome to Easy Rentals',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'What would you like to do today?',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF737D8C),
              ),
            ),
            const SizedBox(height: 24),

            _buildActionCard(
              icon: Icons.home_outlined,
              title: 'Browse Property',
              onTap: () => onNavigateToTab(1),
            ),
            const SizedBox(height: 18),

            _buildActionCard(
              icon: Icons.calendar_month_outlined,
              title: 'My Requests',
              onTap: () => onNavigateToTab(2),
            ),
            const SizedBox(height: 18),

            _buildActionCard(
              icon: Icons.chat_bubble_outline,
              title: 'Send Inquiry',
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

            _buildActionCard(
              icon: Icons.star_outline,
              title: 'Feedback',
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
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
              color: const Color(0xFFE8EDF4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: primaryBlue,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
