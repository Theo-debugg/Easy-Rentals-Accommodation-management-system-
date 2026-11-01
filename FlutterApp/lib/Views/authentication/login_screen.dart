import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/ViewModels/auth_view_model.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_button.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_textfield.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/main_shell.dart';
import 'package:easy_rentals_mobile_app/Views/authentication/signup_screen.dart';

/// Email/password sign-in screen.
///
/// Validates that both fields are non-empty, delegates to [AuthViewModel] to
/// sign the user in, and on success navigates to [MainShell] (replacing this
/// route so the user can't navigate back to login). Failures are surfaced via
/// snackbars.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for the two input fields.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // True while a sign-in request is in-flight; disables the button and
  // swaps its label to "Logging in...".
  bool _isLoading = false;

  // Owns the actual Supabase auth call.
  final AuthViewModel _auth = AuthViewModel();

  /// Validates inputs, signs in, and navigates to the main shell.
  ///
  /// - Empty email or password → snackbar, no request.
  /// - Success → [MainShell] via `pushReplacement` (clears the login route).
  /// - Any error → snackbar with the error's string form.
  Future<void> _login() async {
    // Trim both fields so stray whitespace doesn't fail auth.
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.signIn(email: email, password: password);

      // Guard: widget may have been popped while awaiting the network call.
      if (mounted) {
        // Replace so the back button doesn't return to the login screen.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      // Surface the underlying error (e.g. invalid credentials).
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
    // Release controllers when the screen is torn down.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeArea keeps content out of notches/status bars.
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            // Stretch children so inputs and the button fill the width.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand logo.
              Image.asset('assets/easy-rentals-group-logo.webp',
                        height: 110, width: 110, fit: BoxFit.contain),

                    const SizedBox(height: 16),
              //const Spacer(flex: 2),
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
              // Flexible gap pushing the form down the screen.
              const Spacer(flex: 2),

              // Email input.
              CustomTextField(
                label: 'Email/Username',
                hint: 'Enter your email/username',
                controller: _emailController,
              ),
              const SizedBox(height: 16),

              // Password input (masked).
              CustomTextField(
                label: 'Password',
                hint: 'Enter your password',
                obscureText: true,
                controller: _passwordController,
              ),
              const SizedBox(height: 32),

              // Submit button; disabled and relabelled while loading.
              CustomButton(
                text: _isLoading ? 'Logging in...' : 'Login',
                onPressed: _isLoading ? null : _login,
              ),

              // Flexible gap pushing the signup link to the bottom.
              const Spacer(),

              // Navigate to the signup screen (push so back returns here).
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text(
                  'No account? Create one',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}