/// A simple enquiry (subject + message) created by a student.
///
/// Used mainly as a convenient payload builder: [toMap] produces the row
/// shape expected by the `enquiries` table, tagging it with the caller's
/// `user_id`.
class Enquiry {
  /// Subject line of the enquiry.
  final String subject;

  /// Body of the enquiry message.
  final String message;

  /// When the enquiry was created.
  final DateTime createdAt;

  const Enquiry({required this.subject, required this.message, required this.createdAt});

  /// Serialises this enquiry to a Supabase row map.
  ///
  /// [userId] identifies the sender and is written under `user_id` (the
  /// `enquiries` table's student foreign key). `created_at` is written as an
  /// ISO-8601 string.
  Map<String, dynamic> toMap({required String userId}) => {'user_id': userId, 'subject': subject, 'message': message, 'created_at': createdAt.toIso8601String()};
}