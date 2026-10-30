import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/ViewModels/enquiry_view_model.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_bottom_nav.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_button.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/main_shell.dart';

/// Lets a signed-in student send a free-form enquiry (subject + message).
///
/// Submission is delegated to [EnquiryViewModel], which validates the input
/// again and writes the row to Supabase. On success, a confirmation dialog is
/// shown; dismissing it pops this screen.
class SendEnquiryScreen extends StatefulWidget {
  /// Optional subject pre-filled into the subject field.
  ///
  /// Typically supplied by [RoomDetailsScreen] as
  /// `'Enquiry about <room title>'` so the user doesn't have to retype it.
  final String? initialSubject;

  const SendEnquiryScreen({super.key, this.initialSubject});

  @override
  State<SendEnquiryScreen> createState() => _SendEnquiryScreenState();
}

class _SendEnquiryScreenState extends State<SendEnquiryScreen> {
  // Subject field. Declared `late final` because it's created in initState
  // (once widget.initialSubject is available).
  late final TextEditingController _subjectController;

  // Message field. Created immediately since it never depends on widget args.
  final TextEditingController _messageController = TextEditingController();

  // Thin wrapper around the `enquiries` insert; owns validation for the
  // signed-in user and blank-field checks on the data layer too.
  final EnquiryViewModel _enquiryViewModel = EnquiryViewModel();

  // True while the enquiry is being submitted (disables the button and
  // changes its label to "Submitting...").
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Seed the subject field with any pre-supplied value.
    _subjectController =
        TextEditingController(text: widget.initialSubject ?? '');
  }

  @override
  void dispose() {
    // Release both controllers when the screen is removed from the tree.
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Validates the form and submits the enquiry.
  ///
  /// Client-side checks (subject and message non-empty) run first so obvious
  /// problems are reported without a network round-trip. On success, a
  /// confirmation dialog is shown; OK pops both the dialog and this screen.
  /// Any failure surfaces as a snackbar.
  Future<void> _submit() async {
    // Validate the subject locally (also validated in EnquiryViewModel).
    if (_subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a subject.')),
      );
      return;
    }

    // Validate the message body locally.
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your message.')),
      );
      return;
    }

    // Lock the UI while the insert is in-flight.
    setState(() => _isLoading = true);
    try {
      // Delegate to the view model; it trims, validates, and inserts.
      await _enquiryViewModel.submit(
        subject: _subjectController.text,
        message: _messageController.text,
      );

      // Bail out if the widget was disposed while awaiting the network call.
      if (!mounted) return;

      // Success confirmation; OK closes the dialog and pops this screen.
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Enquiry Submitted'),
          content: const Text(
            'Your enquiry has been saved successfully. '
            'Our team will review it.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Any error from the view model (auth, validation, Postgres, etc.).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not submit enquiry: $e')),
        );
      }
    } finally {
      // Re-enable the button, unless the widget was disposed.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Send Enquiry', style: TextStyle(fontSize: 16)),
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
          // Stretch children to fill horizontal space (labels, fields, button).
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Subject label + field.
            const Text(
              'Subject:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                hintText: 'Leave Tenant Query',
                // Solid white fill with no border, overriding the theme's
                // default outlined input for a cleaner look.
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Message label + multi-line field.
            const Text(
              'Message:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              // Six visible lines — enough for a short enquiry without
              // forcing the whole form to scroll on most devices.
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Type your enquiry or message here',
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button; label reflects in-flight state and is disabled
            // while submitting.
            CustomButton(
              text: _isLoading ? 'Submitting...' : 'Submit Enquiry',
              onPressed: _isLoading ? null : _submit,
            ),
          ],
        ),
      ),

      // "Messages" is index 3 in the shared bottom nav.
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 3,
        onTap: (index) => MainShell.goToTab(context, index),
      ),
    );
  }
}