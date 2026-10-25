import 'package:easy_rentals_mobile_app/Models/student.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:easy_rentals_mobile_app/models/student.dart';

/// Owns authentication and account operations; widgets only collect input and render state.
class AuthViewModel {
  AuthViewModel({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  Student? get currentStudent {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return Student.fromAuthUser(id: user.id, email: user.email, metadata: user.userMetadata);
  }

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<void> signUp({required String fullName, required String email, required String password}) async {
    await _client.auth.signUp(email: email.trim(), password: password, data: {'full_name': fullName.trim()});
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> updateProfile({required String fullName, required String email}) async {
    await _client.auth.updateUser(UserAttributes(email: email.trim(), data: {'full_name': fullName.trim()}));
  }

  Future<void> changePassword(String password) async {
    if (password.trim().length < 6) throw ArgumentError('Password must be at least 6 characters.');
    await _client.auth.updateUser(UserAttributes(password: password.trim()));
  }
}
