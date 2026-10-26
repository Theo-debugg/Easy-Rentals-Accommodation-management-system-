
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/models/appointment.dart';
import 'package:easy_rentals_mobile_app/models/viewing_request.dart';

/// Central place for creating and retrieving viewing requests.
class RequestsViewModel extends ChangeNotifier {
  RequestsViewModel._();
  static final RequestsViewModel instance = RequestsViewModel._();
  final List<ViewingRequest> _requests = [
    const ViewingRequest(propertyTitle: 'Sunset Student Residence', propertyAddress: 'Blenheim', room: 'Room 4', date: 'Oct 10, 2026', time: '12:00 PM', status: 'Approved'),
    const ViewingRequest(propertyTitle: 'Sunset Student Residence', propertyAddress: 'Blenheim', room: 'Room 5, single', date: 'Oct 12, 2026', time: '10:00 AM', status: 'Review'),
  ];
  List<ViewingRequest> get requests => List.unmodifiable(_requests);

  Future<void> submit(Appointment appointment) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Please log in before requesting a viewing.');
    final saved = Appointment(userId: user.id, propertyTitle: appointment.propertyTitle, propertyAddress: appointment.propertyAddress, room: appointment.room, viewingDate: appointment.viewingDate, viewingTime: appointment.viewingTime, status: appointment.status);
    await client.from('viewing_request').insert(saved.toMap());
    final date = saved.viewingDate;
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    _requests.insert(0, ViewingRequest(propertyTitle: saved.propertyTitle, propertyAddress: saved.propertyAddress, room: saved.room, date: '${months[date.month - 1]} ${date.day}, ${date.year}', time: saved.viewingTime, status: saved.status));
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
      _requests..clear()..addAll((rows as List).map((row) {
      final a = Appointment.fromMap(Map<String, dynamic>.from(row as Map));
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return ViewingRequest(propertyTitle: a.propertyTitle, propertyAddress: a.propertyAddress, room: a.room, date: '${months[a.viewingDate.month - 1]} ${a.viewingDate.day}, ${a.viewingDate.year}', time: a.viewingTime, status: a.status);
      }));
      notifyListeners();
    } catch (_) {
      // Keep sample/local requests visible if the table is not configured or offline.
    }
  }
}
