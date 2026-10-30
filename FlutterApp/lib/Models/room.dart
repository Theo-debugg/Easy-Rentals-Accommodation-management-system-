/// Immutable model of a rentable room, decoded from a `room` row (including
/// its embedded `room_photo` relations).
///
/// The factory [Room.fromMap] handles two shapes for `amenities` (JSON list or
/// comma-separated string) and normalises the nested `room_photo` array into a
/// plain list of URL strings, ordered oldest-first.
class Room {
  /// Primary key of the room row.
  final String id;

  /// Foreign key to the owning property.
  final String propertyId;

  /// Human-readable room number (e.g. "12", "A3").
  final String roomNumber;

  /// Room type/category (e.g. "Single", "En-suite"). Defaults to "Room".
  final String roomType;

  /// Monthly price. Declared `num` so it accepts both ints and doubles from
  /// Postgres/JSON.
  final num price;

  /// Free-text description (may be empty).
  final String description;

  /// Availability string (e.g. "Available", "Occupied"). Defaults to
  /// "Unknown" when missing.
  final String availability;

  /// Parsed list of amenity labels.
  final List<String> amenities;

  /// Last update timestamp, if present.
  final DateTime? updatedAt;

  /// Optional staff member assigned to the room.
  final String? staffId;

  /// Ordered list of photo URLs (oldest-first). Defaults to empty.
  final List<String> photoUrls;

  const Room({
    required this.id,
    required this.propertyId,
    required this.roomNumber,
    required this.roomType,
    required this.price,
    required this.description,
    required this.availability,
    required this.amenities,
    this.updatedAt,
    this.staffId,
    this.photoUrls = const [],
  });

  // Backward compatibility for widgets using room.photoUrl.
  /// Convenience getter returning the first photo URL (or `null` if none).
  String? get photoUrl =>
      photoUrls.isEmpty ? null : photoUrls.first;

  /// `true` when [availability] is "available" (case-insensitive, trimmed).
  bool get isAvailable =>
      availability.trim().toLowerCase() == 'available';

  /// Decodes a [Room] from a Supabase row map.
  ///
  /// - `amenities`: accepts either a JSON list (each element stringified) or a
  ///   comma-separated string (trimmed, empties dropped).
  /// - `room_photo`: accepts the nested relation returned by
  ///   `select('*, room_photo(...)')`, sorts the photos by `created_at`
  ///   ascending (so the first uploaded photo shows first), and extracts
  ///   non-blank `photo_url` values.
  factory Room.fromMap(Map<String, dynamic> map) {
    // --- Amenities -------------------------------------------------------
    final rawAmenities = map['amenities'];
    final List<String> parsedAmenities;

    if (rawAmenities is List) {
      // JSON list of values (strings or otherwise) → list of strings.
      parsedAmenities =
          rawAmenities.map((item) => item.toString()).toList();
    } else if (rawAmenities is String &&
        rawAmenities.trim().isNotEmpty) {
      // Legacy comma-separated string → trimmed, non-empty entries.
      parsedAmenities = rawAmenities
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    } else {
      // Missing or empty → no amenities.
      parsedAmenities = [];
    }

    // --- Photos ----------------------------------------------------------
    final rawPhotos = map['room_photo'];
    final photos = <Map<String, dynamic>>[];

    // Only accept actual maps from the nested relation.
    if (rawPhotos is List) {
      for (final item in rawPhotos) {
        if (item is Map) {
          photos.add(Map<String, dynamic>.from(item));
        }
      }
    }

    // Show the oldest uploaded photo first.
    photos.sort((a, b) {
      final dateA = DateTime.tryParse(
        a['created_at']?.toString() ?? '',
      );
      final dateB = DateTime.tryParse(
        b['created_at']?.toString() ?? '',
      );

      // Missing/invalid dates sort last (or tie when both are missing).
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateA.compareTo(dateB);
    });

    // Extract non-blank photo URLs in the sorted order.
    final photoUrls = photos
        .map((photo) => photo['photo_url']?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    return Room(
      id: map['id']?.toString() ?? '',
      propertyId: map['property_id']?.toString() ?? '',
      roomNumber: map['room_number']?.toString() ?? '',
      roomType: map['room_type']?.toString() ?? 'Room',
      // `num.tryParse` handles both ints and numeric strings; default 0.
      price: num.tryParse(map['price']?.toString() ?? '') ?? 0,
      description: map['description']?.toString() ?? '',
      availability: map['availability']?.toString() ?? 'Unknown',
      amenities: parsedAmenities,
      updatedAt: DateTime.tryParse(
        map['updated_at']?.toString() ?? '',
      ),
      staffId: map['staff_id']?.toString(),
      photoUrls: photoUrls,
    );
  }
}