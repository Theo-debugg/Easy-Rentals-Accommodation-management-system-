import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Models/appointment.dart';
import 'package:easy_rentals_mobile_app/Models/viewing_request.dart';

/// Central place for creating, retrieving, and cancelling viewing requests.
///
/// Implemented as a singleton [ChangeNotifier] so all screens observe the same
/// in-memory list of requests.
class RequestsViewModel extends ChangeNotifier {
  // Private constructor enforces the singleton pattern.
  RequestsViewModel._();

  /// The shared singleton instance.
  static final RequestsViewModel instance = RequestsViewModel._();

  // In-memory cache of the user's viewing requests, newest first.
  final List<ViewingRequest> _requests = [];

  /// Read-only view over the cached requests.
  List<ViewingRequest> get requests => List.unmodifiable(_requests);

  /// Submits a new viewing request derived from [appointment].
  ///
  /// Requires a signed-in user and a valid `roomId`. On success, inserts the
  /// row into `viewing_request`, retrieves the generated ID, prepends a
  /// [ViewingRequest] to the local list, and notifies listeners.
  Future<void> submit(Appointment appointment) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('Please log in before requesting a viewing.');
    }

    // A room must be selected before a viewing can be requested.
    if (appointment.roomId == null || appointment.roomId!.isEmpty) {
      throw Exception(
        'No room ID was provided. Please select a room and try again.',
      );
    }

    // Rebuild the appointment with the authenticated user's ID and a
    // lowercased status, ensuring consistency with the database.
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

    // Format the viewing date for display (e.g. "Jan 15, 2025").
    final date = saved.viewingDate;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    // Prepend the new request locally so the UI updates immediately.
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

  /// Reloads the current user's viewing requests from Supabase, replacing the
  /// local cache.
  ///
  /// No-op when signed out. Failures are logged but do not throw, so the UI
  /// keeps showing whatever was previously loaded.
  Future<void> refreshFromSupabase() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) return;

    try {
      // Fetch only this user's requests, newest preferred_date first.
      final rows = await client
          .from('viewing_request')
          .select()
          .eq('user_id', user.id)
          .order('preferred_date', ascending: false);

      // Map each row to a [ViewingRequest] for display.
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

  /// Cancel/delete a viewing request.
  ///
  /// Deletes the row from `viewing_request` (scoped to the current user) and
  /// removes it from the local cache. Throws if the row could not be deleted.
  Future<void> deleteRequest(String requestId) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      throw Exception('Please log in before cancelling a request.');
    }

    // Delete and request the affected IDs back so we can detect a no-op.
    final deleted = await client
        .from('viewing_request')
        .delete()
        .eq('id', requestId)
        .eq('user_id', user.id)
        .select('id');

    // Empty result means the row wasn't found or RLS blocked the delete.
    if ((deleted as List).isEmpty) {
      throw Exception(
        'Request could not be cancelled. It may no longer exist '
        'or you may not have permission to delete it.',
      );
    }

    // Reflect the deletion locally and notify listeners.
    _requests.removeWhere((request) => request.id == requestId);

    notifyListeners();
  }
}