/// Display model for a viewing request shown in the "My Requests" list.
///
/// Intentionally simple and pre-formatted: [date] is already a human-readable
/// string (e.g. "Jan 15, 2025") and [time] holds the slot label. This keeps
/// the presentation layer free of formatting logic; the underlying
/// [Appointment] holds the raw data.
class ViewingRequest {
  /// Database ID of the row; `null` for requests not yet persisted.
  final String? id;

  /// Property title shown as the card's primary line.
  final String propertyTitle;

  /// Property address shown under the title.
  final String propertyAddress;

  /// Room label (e.g. "Room 12").
  final String room;

  /// Pre-formatted viewing date (e.g. "Jan 15, 2025").
  final String date;

  /// Viewing time slot label (e.g. "09:00 AM - 10:00 AM").
  final String time;

  /// Status string (e.g. "pending", "approved", "cancelled").
  final String status;

  const ViewingRequest({
    this.id,
    required this.propertyTitle,
    required this.propertyAddress,
    required this.room,
    required this.date,
    required this.time,
    required this.status,
  });
}