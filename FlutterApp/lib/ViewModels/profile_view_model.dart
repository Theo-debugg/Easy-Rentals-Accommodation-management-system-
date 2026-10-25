import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_view_model.dart';

/// Keeps profile changes out of the presentation layer.
class ProfileViewModel {
  ProfileViewModel({AuthViewModel? auth}) : _auth = auth ?? AuthViewModel();
  final AuthViewModel _auth;
  User? get currentUser => Supabase.instance.client.auth.currentUser;
  Future<void> update({required String name, required String email}) => _auth.updateProfile(fullName: name, email: email);
  Future<void> changePassword(String password) => _auth.changePassword(password);
}
