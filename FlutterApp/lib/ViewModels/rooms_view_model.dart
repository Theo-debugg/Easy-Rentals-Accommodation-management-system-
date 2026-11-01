import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Models/room.dart';

/// Loads room listings from Supabase and provides simple in-memory filtering.
class RoomsViewModel {
  RoomsViewModel();

  /// Fetches all rooms together with their related photos from `room_photo`.
  ///
  /// Rooms are ordered by most recently updated first. Each row (including
  /// its nested photo relations) is mapped to a [Room] model.
  Future<List<Room>> fetchRooms() async {
    // `select('*, room_photo(...)')` performs a relational fetch so each room
    // includes its list of photos in a single query.
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

  /// Filters [rooms] by a free-text [query] and an availability [status].
  ///
  /// - The query is matched against room number, type, description, property
  ///   ID, and amenities (case-insensitive substring match).
  /// - [status] defaults to `'Available'`; pass `'All'` to bypass the
  ///   availability filter entirely.
  List<Room> filter(
    List<Room> rooms, {
    String query = '',
    String status = 'Available',
  }) {
    final search = query.trim().toLowerCase();

    return rooms.where((room) {
      // Build a single searchable string from the room's textual fields.
      final searchableText = [
        room.roomNumber,
        room.roomType,
        room.description,
        room.propertyId,
        ...room.amenities,
      ].join(' ').toLowerCase();

      // Match the search term anywhere in the combined text.
      final matchesQuery = searchableText.contains(search);

      // `'All'` disables the status filter; otherwise compare case-insensitively.
      final matchesStatus = status == 'All' ||
          room.availability.trim().toLowerCase() ==
              status.toLowerCase();

      return matchesQuery && matchesStatus;
    }).toList(growable: false);
  }
}