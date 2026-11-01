/// A viewing-request appointment submitted by a student for a specific room.
///
/// Used both as the input to [RequestsViewModel.submit] and as the decoded
/// shape of rows fetched from the `viewing_request` table. [toMap] writes a
/// superset of columns (both the legacy `user_id`/`viewing_*` pair and the
/// current `student_id`/`preferred_*` pair) so the same object can be inserted
/// regardless of which schema variant the backend expects.
class Appointment {
  /// Database ID; `null` for a not-yet-inserted appointment.
  final String? id;

  /// Authenticated student's ID (written to `student_id`/`user_id`).
  final String userId;

  /// Human-readable property title.
  final String propertyTitle;

  /// Human-readable property address.
  final String propertyAddress;

  /// Room label (e.g. "Room 12").
  final String room;

  /// Optional `room.id` foreign key.
  final String? roomId;

  /// Preferred viewing date (date portion is written to `*_date`).
  final DateTime viewingDate;

  /// Preferred viewing time as a human-readable slot string
  /// (e.g. "09:00 AM - 10:00 AM"). The first time in the slot is parsed and
  /// normalised to 24-hour format for the `preferred_time` column.
  final String viewingTime;

  /// Current status; defaults to `'pending'`.
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

  /// Serialises this appointment to a Supabase row map.
  ///
  /// Writes both the legacy (`user_id`, `viewing_date`, `viewing_time`) and
  /// current (`student_id`, `preferred_date`, `preferred_time`) column names
  /// so the insert succeeds against either schema revision. Date columns use
  /// the ISO-8601 date-only form (`YYYY-MM-DD`); `preferred_time` is converted
  /// to a Postgres `time` value by [_toPostgresTime].
  Map<String, dynamic> toMap() => {
        'student_id': userId,
        'user_id': userId,
        'property_title': propertyTitle,
        'property_address': propertyAddress,
        'room': room,
        'room_id': roomId,

        // Date-only ISO string, e.g. "2025-01-15".
        'preferred_date':
            viewingDate.toIso8601String().split('T').first,
        'viewing_date':
            viewingDate.toIso8601String().split('T').first,

        // Postgres time value (HH:MM:00), plus the raw slot for the legacy
        // column.
        'preferred_time': _toPostgresTime(viewingTime),
        'viewing_time': viewingTime,
        'status': status,
      };

  /// Converts a 12-hour time slot (e.g. "09:00 AM - 10:00 AM") into a
  /// Postgres-compatible `HH:MM:SS` string.
  ///
  /// Only the **first** time in the slot is parsed. Throws [FormatException]
  /// when the string doesn't start with a valid `HH[:MM] AM|PM` prefix or
  /// falls outside 01:00–12:59.
  String _toPostgresTime(String value) {
    // Match an optional leading time, optionally followed by ":MM", then AM/PM.
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

    // 12-hour clock bounds check.
    if (hour < 1 || hour > 12 || minute > 59) {
      throw FormatException('Invalid viewing time slot: $value');
    }

    // 12 AM → 00, otherwise unchanged; 12 PM → 12, otherwise add 12.
    if (period == 'AM') {
      if (hour == 12) hour = 0;
    } else {
      if (hour != 12) hour += 12;
    }

    // Zero-pad to HH:MM:00.
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:00';
  }

  /// Decodes an appointment from a Supabase row map.
  ///
  /// Prefers the current column names (`user_id` is used for backwards
  /// compatibility when `student_id` is missing; `preferred_date`/`_time`
  /// take precedence over `viewing_date`/`_time`). Missing or unparseable
  /// values fall back to sensible defaults (`''`, `DateTime.now()`,
  /// `'pending'`).
  factory Appointment.fromMap(Map<String, dynamic> map) =>
      Appointment(
        id: map['id']?.toString(),
        // Accept either column name; default to empty.
        userId: map['user_id']?.toString() ??
            map['student_id']?.toString() ??
            '',
        propertyTitle: map['property_title']?.toString() ?? '',
        propertyAddress:
            map['property_address']?.toString() ?? '',
        room: map['room']?.toString() ?? '',
        roomId: map['room_id']?.toString(),
        // Prefer the current column, then the legacy one; default to now.
        viewingDate: DateTime.tryParse(
              (map['preferred_date'] ?? map['viewing_date'])
                      ?.toString() ??
                  '',
            ) ??
            DateTime.now(),
        // Prefer the current column, then the legacy one; default to empty.
        viewingTime:
            (map['preferred_time'] ?? map['viewing_time'])
                    ?.toString() ??
                '',
        status: map['status']?.toString() ?? 'pending',
      );
}