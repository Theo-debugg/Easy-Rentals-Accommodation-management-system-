import 'package:easy_rentals_mobile_app/models/enquiry.dart';

/// Keeps enquiry validation/state out of the UI. This remains local until an
/// enquiries table and its access policies are configured in Supabase.
class EnquiryViewModel {
  final List<Enquiry> _submitted = [];
  List<Enquiry> get submitted => List.unmodifiable(_submitted);

  Future<void> submit({required String subject, required String message}) async {
    final cleanSubject = subject.trim();
    final cleanMessage = message.trim();
    if (cleanSubject.isEmpty) throw ArgumentError('Please enter a subject.');
    if (cleanMessage.isEmpty) throw ArgumentError('Please enter your message.');
    _submitted.insert(0, Enquiry(subject: cleanSubject, message: cleanMessage, createdAt: DateTime.now()));
  }
}
