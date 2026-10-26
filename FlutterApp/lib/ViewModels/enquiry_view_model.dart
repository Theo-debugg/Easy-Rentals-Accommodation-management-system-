import 'package:supabase_flutter/supabase_flutter.dart';

class EnquiryViewModel {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> submit({
    required String subject,
    required String message,
    String? propertyId,
    String? roomId,
  }) async {
    final cleanSubject = subject.trim();
    final cleanMessage = message.trim();

    if (cleanSubject.isEmpty) {
      throw ArgumentError('Please enter a subject.');
    }

    if (cleanMessage.isEmpty) {
      throw ArgumentError('Please enter your message.');
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw Exception('Please log in before submitting an enquiry.');
    }

    final enquiryData = <String, dynamic>{
      'student_id': user.id,
      'subject': cleanSubject,
      'message': cleanMessage,
      'status': 'Pending',
    };

    if (propertyId != null && propertyId.trim().isNotEmpty) {
      enquiryData['property_id'] = propertyId.trim();
    }

    if (roomId != null && roomId.trim().isNotEmpty) {
      enquiryData['room_id'] = roomId.trim();
    }

    await _supabase
        .from('enquiries')
        .insert(enquiryData);
  }
}