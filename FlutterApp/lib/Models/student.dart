/// Lightweight representation of the signed-in student.
///
/// Built from a Supabase `User` (see [Student.fromAuthUser]) so screens can
/// work with a typed model rather than poking at `userMetadata` directly.
class Student {
  /// Supabase auth user ID.
  final String id;

  /// Display name, read from `userMetadata['full_name']`.
  final String fullName;

  /// Email address (empty string if the auth user has none).
  final String email;

  const Student({required this.id, required this.fullName, required this.email});

  /// Builds a [Student] from the fields of a Supabase auth user.
  ///
  /// - [fullName] is read from `metadata['full_name']` and defaults to `''`
  ///   when absent.
  /// - [email] defaults to `''` when the user has no email (e.g. phone-only
  ///   auth).
  factory Student.fromAuthUser({required String id, String? email, Map<String, dynamic>? metadata}) => Student(id: id, fullName: (metadata?['full_name'] as String?) ?? '', email: email ?? '');
}