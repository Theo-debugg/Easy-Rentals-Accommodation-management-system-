import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_view_model.dart';

/// Keeps profile changes out of the presentation layer.
///
/// Acts as a thin wrapper around [AuthViewModel] so UI code can update the
/// profile or password without touching Supabase directly.
class ProfileViewModel {
  // Allows an [AuthViewModel] to be injected for testing; otherwise a default
  // instance is created.
  ProfileViewModel({AuthViewModel? auth}) : _auth = auth ?? AuthViewModel();

  final AuthViewModel _auth;

  /// The currently signed-in Supabase user (or `null` if signed out).
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  /// Updates the current user's display name and email.
  Future<void> update({required String name, required String email}) =>
      _auth.updateProfile(fullName: name, email: email);

  /// Changes the current user's password.
  Future<void> changePassword(String password) =>
      _auth.changePassword(password);
}
