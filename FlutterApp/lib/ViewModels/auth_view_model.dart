import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Models/student.dart';

/// Owns authentication and account operations; widgets only collect input and render state.
class AuthViewModel {
  // Allows a Supabase client to be injected for testing; falls back to the
  // globally initialised client in production.
  AuthViewModel({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns the currently logged-in student, or `null` if no user is signed in.
  Student? get currentStudent {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    // Build a [Student] from the Supabase user ID, email, and custom metadata
    // (e.g. `full_name`) stored on the auth user.
    return Student.fromAuthUser(
      id: user.id,
      email: user.email,
      metadata: user.userMetadata,
    );
  }

  /// Signs a user in with email and password.
  ///
  /// Email is trimmed to avoid whitespace-related auth failures.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registers a new user with the given name, email, and password.
  ///
  /// The display name is stored in the auth user's metadata under `full_name`
  /// so it can be retrieved later via [currentStudent].
  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
  }

  /// Signs the current user out of the app.
  Future<void> signOut() => _client.auth.signOut();

  /// Updates the current user's profile email and display name.
  Future<void> updateProfile({
    required String fullName,
    required String email,
  }) async {
    await _client.auth.updateUser(
      UserAttributes(
        email: email.trim(),
        data: {'full_name': fullName.trim()},
      ),
    );
  }

  /// Changes the current user's password.
  ///
  /// Throws an [ArgumentError] if the password is shorter than 6 characters.
  Future<void> changePassword(String password) async {
    if (password.trim().length < 6) {
      throw ArgumentError('Password must be at least 6 characters.');
    }
    await _client.auth.updateUser(
      UserAttributes(password: password.trim()),
    );
  }
}