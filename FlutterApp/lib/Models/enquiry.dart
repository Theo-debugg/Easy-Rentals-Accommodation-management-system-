class Enquiry {
  final String subject;
  final String message;
  final DateTime createdAt;

  const Enquiry({required this.subject, required this.message, required this.createdAt});

  Map<String, dynamic> toMap({required String userId}) => {'user_id': userId, 'subject': subject, 'message': message, 'created_at': createdAt.toIso8601String()};
}
