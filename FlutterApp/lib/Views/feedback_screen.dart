import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_bottom_nav.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_button.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/main_shell.dart';

/// Lets a signed-in student rate the app and leave an optional comment.
///
/// Feedback is written to the `feedback` table with the student's user ID, a
/// 1–5 star rating, and an optional free-text comment. On success, a thank-you
/// dialog is shown, and dismissing it pops this screen.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  // Currently selected star rating (1–5). Defaults to 4.
  int _rating = 4;

  // Holds the optional free-text comment entered by the user.
  final TextEditingController _controller = TextEditingController();

  // Guards against duplicate submissions (disables the button and inputs
  // while the insert is in-flight).
  bool _isSubmitting = false;

  @override
  void dispose() {
    // Free the controller when the screen is removed from the tree.
    _controller.dispose();
    super.dispose();
  }

  /// Validates the session, inserts the feedback row, and reports the result.
  ///
  /// - No-ops if a submission is already in progress.
  /// - Requires a signed-in user; shows a snackbar otherwise.
  /// - On success: shows a thank-you dialog, then pops this screen when the
  ///   user taps OK.
  /// - On [PostgrestException]: shows a snackbar with the server message.
  /// - On any other error: shows a generic failure snackbar.
  /// - Always resets [_isSubmitting] in `finally` (if still mounted).
  Future<void> _submit() async {
    // Prevent double-taps while a request is in flight.
    if (_isSubmitting) return;

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    // Feedback must be associated with a signed-in student.
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in before submitting feedback.'),
        ),
      );
      return;
    }

    // Lock the UI: disables stars, the text field, and the submit button.
    setState(() => _isSubmitting = true);

    try {
      // Send `comments` as null when the field is blank, rather than an
      // empty string, so the database column stays cleanly nullable.
      await client.from('feedback').insert({
        'student_id': user.id,
        'rating': _rating,
        'comments': _controller.text.trim().isEmpty
            ? null
            : _controller.text.trim(),
      });

      // The widget could have been disposed while awaiting the network call.
      if (!mounted) return;

      // Blocking success dialog: not dismissible by tapping outside.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Thank you!'),
          content: const Text(
            'Your feedback has been submitted successfully.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog first, then the feedback screen itself.
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on PostgrestException catch (e) {
      // Surface the server-side error message (e.g. RLS or validation).
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save feedback: ${e.message}'),
        ),
      );
    } catch (e) {
      // Any non-Supabase failure: show a user-friendly fallback message.
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
          ),
        ),
      );
    } finally {
      // Re-enable the UI, but only if the widget is still alive.
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Give Your Feedback',
          style: TextStyle(fontSize: 16),
        ),
        // Transparent app bar so it blends into the scaffold background.
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // Stretch children to fill horizontal space (text, field, button).
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Intro copy explaining the value of the feedback.
            const Text(
              'Thanks for taking the time to tell us your thoughts, '
              'it means a lot to us.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'If you have more to share, please add it below.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Star rating: filled stars up to `_rating`, outline stars after.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  // Accessibility tooltip: "1 star" / "2 stars" / etc.
                  tooltip: '${index + 1} star${index == 0 ? '' : 's'}',
                  icon: Icon(
                    // `index < _rating` means this star is "on".
                    index < _rating ? Icons.star : Icons.star_border,
                    color: index < _rating ? Colors.amber : Colors.grey,
                    size: 32,
                  ),
                  // Tapping sets the rating to `index + 1` (1-based).
                  onPressed: _isSubmitting
                      ? null
                      : () => setState(() => _rating = index + 1),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Optional multi-line comment field.
            TextField(
              controller: _controller,
              maxLines: 6,
              enabled: !_isSubmitting,
              decoration: InputDecoration(
                hintText: 'Share your thoughts',
                // Solid white fill with no border, overriding the theme's
                // default outlined input.
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit button; label reflects in-flight state and is disabled
            // while submitting (via CustomButton passing onPressed: _submit,
            // which early-returns on the guard).
            CustomButton(
              text: _isSubmitting
                  ? 'Submitting...'
                  : 'Submit Feedback',
              onPressed: _submit,
            ),
          ],
        ),
      ),

      // Reuse the shared bottom nav so users can jump to any main tab.
      // Tapping an item delegates to MainShell.goToTab, which swaps the shell's
      // active tab and pops this screen.
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) => MainShell.goToTab(context, index),
      ),
    );
  }
}//feedback_screen.dart