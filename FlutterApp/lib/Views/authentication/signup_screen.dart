import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/ViewModels/auth_view_model.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_button.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_textfield.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/main_shell.dart';

/// Account registration screen.
///
/// Collects a name, email, password, and confirmation, validates them, then
/// delegates to [AuthViewModel.signUp] (which stores the name in the auth
/// user's metadata). On success, navigates to [MainShell] via
/// `pushReplacement` so the user can't go back to this screen.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // One controller per field.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // True while the signup request is in-flight; disables the button and
  // swaps its label to "Signing up...".
  bool _isLoading = false;

  // Owns the actual Supabase signup call.
  final AuthViewModel _auth = AuthViewModel();

  /// Validates the form, creates the account, and navigates to [MainShell].
  ///
  /// Validation:
  /// 1. Name, email, and password must all be non-empty.
  /// 2. Password and confirmation must match.
  ///
  /// On success → [MainShell] (replacing this route). On failure → snackbar.
  Future<void> _signup() async {
    // Trim all fields before validating.
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Required-fields check.
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Passwords must match before hitting the network.
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Delegate to the view model; it trims and posts to Supabase.
      await _auth.signUp(fullName: name, email: email, password: password);

      // Guard: widget may have been disposed while awaiting the request.
      if (mounted) {
        // Replace so the back button doesn't return to the signup screen.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      // Surface the error (e.g. email already registered).
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      // Re-enable the button unless the screen was disposed.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    // Release all controllers when the screen is torn down.
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Transparent app bar with a back button to return to login.
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          // Horizontal padding only; vertical spacing is handled by the
          // content itself so the scroll view isn't cramped at the top.
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          // Wrap in a scroll view so the form remains usable on small
          // screens and when the keyboard is open.
          child: SingleChildScrollView(
            child: Column(
              // Stretch children so inputs and the button fill the width.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Marketing/welcome heading.
                const Text(
                  'Welcome to\nEasy Rentals\naccommodation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 32),

                // Full name input.
                CustomTextField(label: 'Name', hint: 'Enter your name', controller: _nameController),
                const SizedBox(height: 16),

                // Email input.
                CustomTextField(label: 'Email', hint: 'Enter your email', controller: _emailController),
                const SizedBox(height: 16),

                // Password input (masked).
                CustomTextField(
                  label: 'Password',
                  hint: 'Enter your password',
                  obscureText: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 16),

                // Password confirmation (masked).
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  obscureText: true,
                  controller: _confirmPasswordController,
                ),
                const SizedBox(height: 32),

                // Submit button; disabled and relabelled while loading.
                CustomButton(
                  text: _isLoading ? 'Signing up...' : 'Sign up',
                  onPressed: _isLoading ? null : _signup,
                ),
                const SizedBox(height: 16),

                // Return to the login screen (pops this route).
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Text(
                    'Already have account? Sign in',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}