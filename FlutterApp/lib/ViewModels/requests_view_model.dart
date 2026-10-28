
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Models/appointment.dart';
import 'package:easy_rentals_mobile_app/Models/viewing_request.dart';

/// Central place for creating, retrieving, and cancelling viewing requests.
class RequestsViewModel extends ChangeNotifier {
  RequestsViewModel._();

  static final RequestsViewModel instance = RequestsViewModel._();

  final List<ViewingRequest> _requests = [];

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

    // Save the request and retrieve its database ID.
    final inserted = await client
        .from('viewing_request')
        .insert(saved.toMap())
        .select('id')
        .single();

    final date = saved.viewingDate;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    _requests.insert(
      0,
      ViewingRequest(
        id: inserted['id']?.toString(),
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
          final data = Map<String, dynamic>.from(row as Map);

          final appointment = Appointment.fromMap(data);

          const months = [
            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
          ];

          final date = appointment.viewingDate;

          return ViewingRequest(
            id: data['id']?.toString(),
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

  // Cancel/delete a viewing request.
  Future<void> deleteRequest(String requestId) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('Please log in before cancelling a request.');
    }

    final deleted = await client
        .from('viewing_request')
        .delete()
        .eq('id', requestId)
        .eq('user_id', user.id)
        .select('id');

    if ((deleted as List).isEmpty) {
      throw Exception(
        'Request could not be cancelled. It may no longer exist '
        'or you may not have permission to delete it.',
      );
    }

    _requests.removeWhere((request) => request.id == requestId);

    notifyListeners();
  }
}
