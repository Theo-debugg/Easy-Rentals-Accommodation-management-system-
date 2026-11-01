import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/ViewModels/profile_view_model.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_button.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_textfield.dart';

/// The "Profile" tab of [MainShell].
///
/// Lets the signed-in student view/edit their display name and email, change
/// their password, and save the updates via [ProfileViewModel].
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // Controllers for the profile form.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  // True while a save or password change is in-flight.
  bool _isLoading = false;

  // Owns the actual Supabase profile/password updates.
  final ProfileViewModel _profile = ProfileViewModel();

  @override
  void initState() {
    super.initState();
    // Seed the form fields from the current auth user, when available.
    final user = _profile.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _nameController.text = user.userMetadata?['full_name'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Saves the current name/email via [ProfileViewModel].
  ///
  /// Displays a result dialog on success or failure.
  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      await _profile.update(name: _nameController.text, email: _emailController.text);
      if (mounted) {
        _showDialog('Success', 'Profile updated successfully.');
      }
    } catch (e) {
      if (mounted) _showDialog('Error', e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Opens a dialog asking for a new password, then applies it.
  ///
  /// Validation and the actual update happen inside the dialog's "Save"
  /// action; a result dialog is shown when finished. The temporary
  /// [newPasswordController] is created here and not explicitly disposed
  /// (the widget is short-lived and the dialog closes it promptly).
  Future<void> _changePassword() async {
    final newPasswordController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: newPasswordController,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter new password'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Client-side minimum-length check (also enforced in the VM).
              if (newPasswordController.text.trim().length < 6) {
                _showDialog('Error', 'Password must be at least 6 characters.');
                return;
              }
              setState(() => _isLoading = true);
              try {
                await _profile.changePassword(newPasswordController.text);
                if (mounted) _showDialog('Success', 'Password changed successfully.');
              } catch (e) {
                if (mounted) _showDialog('Error', e.toString());
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Shows a simple OK-only result dialog.
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        // Stretch children so inputs and buttons fill the width.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar placeholder.
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple[400],
              child: const Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 24),

          // Editable name field.
          CustomTextField(
            label: 'Name',
            hint: 'Enter your name',
            controller: _nameController,
          ),
          const SizedBox(height: 16),

          // Editable email field.
          CustomTextField(
            label: 'Email',
            hint: 'Enter your email',
            controller: _emailController,
          ),
          const SizedBox(height: 16),

          // Secondary action: open the change-password dialog.
          SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: _isLoading ? null : _changePassword,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                side: const BorderSide(color: Colors.black54),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 18, color: Colors.black54),
                  SizedBox(width: 8),
                  Text(
                    'Change password',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Primary action: save profile changes.
          CustomButton(
            text: _isLoading ? 'Saving...' : 'Save Changes',
            onPressed: _isLoading ? null : _updateProfile,
          ),
        ],
      ),
    );
  }
}