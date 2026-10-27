
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Models/appointment.dart';
import 'package:easy_rentals_mobile_app/Models/viewing_request.dart';

/// Central place for creating and retrieving viewing requests.
class RequestsViewModel extends ChangeNotifier {
  RequestsViewModel._();

  static final RequestsViewModel instance = RequestsViewModel._();

  final List<ViewingRequest> _requests = [
    const ViewingRequest(
      propertyTitle: 'Sunset Student Residence',
      propertyAddress: 'Blenheim',
      room: 'Room 4',
      date: 'Oct 10, 2026',
      time: '12:00 PM',
      status: 'Approved',
    ),
    const ViewingRequest(
      propertyTitle: 'Sunset Student Residence',
      propertyAddress: 'Blenheim',
      room: 'Room 5, single',
      date: 'Oct 12, 2026',
      time: '10:00 AM',
      status: 'Review',
    ),
  ];

  List<ViewingRequest> get requests => List.unmodifiable(_requests);

  Future<void> submit(Appointment appointment) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('Please log in before requesting a viewing.');
    }

    if (appointment.roomId == null ||
        appointment.roomId!.isEmpty) {
      throw Exception(
        'No room ID was provided. Please select a room and try again.',
      );
    }

    final saved = Appointment(
      userId: user.id,
      propertyTitle: appointment.propertyTitle,
      propertyAddress: appointment.propertyAddress,
      room: appointment.room,
      roomId: appointment.roomId,
      viewingDate: appointment.viewingDate,
      viewingTime: appointment.viewingTime,
      status: appointment.status.toLowerCase(),
    );

    await client
        .from('viewing_request')
        .insert(saved.toMap());

    final date = saved.viewingDate;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    _requests.insert(
      0,
      ViewingRequest(
        propertyTitle: saved.propertyTitle,
        propertyAddress: saved.propertyAddress,
        room: saved.room,
        date: '${months[date.month - 1]} '
            '${date.day}, ${date.year}',
        time: saved.viewingTime,
        status: saved.status,
      ),
    );

    notifyListeners();
  }

  Future<void> refreshFromSupabase() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) return;

    try {
      final rows = await client
          .from('viewing_request')
          .select()
          .eq('user_id', user.id)
          .order('preferred_date', ascending: false);

      _requests
        ..clear()
        ..addAll((rows as List).map((row) {
          final appointment = Appointment.fromMap(
            Map<String, dynamic>.from(row as Map),
          );

          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
          ];

          final date = appointment.viewingDate;

          return ViewingRequest(
            propertyTitle: appointment.propertyTitle,
            propertyAddress: appointment.propertyAddress,
            room: appointment.room,
            date: '${months[date.month - 1]} '
                '${date.day}, ${date.year}',
            time: appointment.viewingTime,
            status: appointment.status,
          );
        }));

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh viewing requests: $e');
    }
  }
}
