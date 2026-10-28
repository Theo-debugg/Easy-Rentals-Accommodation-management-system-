
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Models/room.dart';

class RoomsViewModel {
  RoomsViewModel();

  Future<List<Room>> fetchRooms() async {
    final response = await Supabase.instance.client
        .from('room')
        .select('''
          *,
          room_photo (
            id,
            photo_url,
            created_at
          )
        ''')
        .order('updated_at', ascending: false);

    final rows = response as List;

    final rooms = rows.map((row) {
      final roomMap = Map<String, dynamic>.from(row as Map);
      final room = Room.fromMap(roomMap);

      // Temporary debugging: check whether photos reach Flutter.
      print(
        'ROOM: ${room.roomNumber} | '
        'PHOTO URL: ${room.photoUrl}',
      );

      return room;
    }).toList();

    return rooms;
  }

  List<Room> filter(
    List<Room> rooms, {
    String query = '',
    String status = 'Available',
  }) {
    final search = query.trim().toLowerCase();

    return rooms.where((room) {
      final searchableText = [
        room.roomNumber,
        room.roomType,
        room.description,
        room.propertyId,
        ...room.amenities,
      ].join(' ').toLowerCase();

      final matchesQuery = searchableText.contains(search);

      final matchesStatus = status == 'All' ||
          room.availability.trim().toLowerCase() ==
              status.toLowerCase();

      return matchesQuery && matchesStatus;
    }).toList(growable: false);
  }
}
