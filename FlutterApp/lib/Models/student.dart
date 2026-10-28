class Student {
  final String id;
  final String fullName;
  final String email;

  const Student({required this.id, required this.fullName, required this.email});

  factory Student.fromAuthUser({required String id, String? email, Map<String, dynamic>? metadata}) => Student(id: id, fullName: (metadata?['full_name'] as String?) ?? '', email: email ?? '');
}

