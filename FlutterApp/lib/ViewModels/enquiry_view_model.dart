import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles submitting student enquiries (contact/support messages) to Supabase.
class EnquiryViewModel {
  // Uses the globally initialised Supabase client.
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Submits an enquiry to the `enquiries` table.
  ///
  /// [subject] and [message] are required and are validated to be non-empty.
  /// [propertyId] and [roomId] are optional and only included in the payload
  /// when they contain a non-blank value.
  Future<void> submit({
    required String subject,
    required String message,
    String? propertyId,
    String? roomId,
  }) async {
    // Normalise inputs by trimming whitespace.
    final cleanSubject = subject.trim();
    final cleanMessage = message.trim();

    // Basic client-side validation before hitting the database.
    if (cleanSubject.isEmpty) {
      throw ArgumentError('Please enter a subject.');
    }

    if (cleanMessage.isEmpty) {
      throw ArgumentError('Please enter your message.');
    }

    // Enquiries must be tied to a signed-in user.
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please log in before submitting an enquiry.');
    }

    // Base payload: student_id, subject, message, and initial status.
    final enquiryData = <String, dynamic>{
      'student_id': user.id,
      'subject': cleanSubject,
      'message': cleanMessage,
      'status': 'Pending',
    };

    // Attach property_id only if a valid value was supplied.
    if (propertyId != null && propertyId.trim().isNotEmpty) {
      enquiryData['property_id'] = propertyId.trim();
    }

    // Attach room_id only if a valid value was supplied.
    if (roomId != null && roomId.trim().isNotEmpty) {
      enquiryData['room_id'] = roomId.trim();
    }

    // Persist the enquiry row.
    await _supabase
        .from('enquiries')
        .insert(enquiryData);
  }
}