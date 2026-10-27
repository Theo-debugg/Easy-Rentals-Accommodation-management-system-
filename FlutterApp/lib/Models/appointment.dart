
class Appointment {
  final String? id;
  final String userId;
  final String propertyTitle;
  final String propertyAddress;
  final String room;
  final String? roomId;
  final DateTime viewingDate;
  final String viewingTime;
  final String status;

  const Appointment({
    this.id,
    required this.userId,
    required this.propertyTitle,
    required this.propertyAddress,
    required this.room,
    this.roomId,
    required this.viewingDate,
    required this.viewingTime,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() => {
        'student_id': userId,
        'user_id': userId,
        'property_title': propertyTitle,
        'property_address': propertyAddress,
        'room': room,
        'room_id': roomId,

        'preferred_date':
            viewingDate.toIso8601String().split('T').first,
        'viewing_date':
            viewingDate.toIso8601String().split('T').first,

        'preferred_time': _toPostgresTime(viewingTime),
        'viewing_time': viewingTime,
        'status': status,
      };

  String _toPostgresTime(String value) {
    final match = RegExp(
      r'^\s*(\d{1,2})(?::(\d{2}))?\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(value);

    if (match == null) {
      throw FormatException('Invalid viewing time slot: $value');
    }

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2) ?? '0');
    final period = match.group(3)!.toUpperCase();

    if (hour < 1 || hour > 12 || minute > 59) {
      throw FormatException('Invalid viewing time slot: $value');
    }

    if (period == 'AM') {
      if (hour == 12) hour = 0;
    } else {
      if (hour != 12) hour += 12;
    }

    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:00';
  }

  factory Appointment.fromMap(Map<String, dynamic> map) =>
      Appointment(
        id: map['id']?.toString(),
        userId: map['user_id']?.toString() ??
            map['student_id']?.toString() ??
            '',
        propertyTitle: map['property_title']?.toString() ?? '',
        propertyAddress:
            map['property_address']?.toString() ?? '',
        room: map['room']?.toString() ?? '',
        roomId: map['room_id']?.toString(),
        viewingDate: DateTime.tryParse(
              (map['preferred_date'] ?? map['viewing_date'])
                      ?.toString() ??
                  '',
            ) ??
            DateTime.now(),
        viewingTime:
            (map['preferred_time'] ?? map['viewing_time'])
                    ?.toString() ??
                '',
        status: map['status']?.toString() ?? 'pending',
      );
}
