
class Room {
  final String id;
  final String propertyId;
  final String roomNumber;
  final String roomType;
  final num price;
  final String description;
  final String availability;
  final List<String> amenities;
  final DateTime? updatedAt;
  final String? staffId;
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
  String? get photoUrl =>
      photoUrls.isEmpty ? null : photoUrls.first;

  bool get isAvailable =>
      availability.trim().toLowerCase() == 'available';

  factory Room.fromMap(Map<String, dynamic> map) {
    final rawAmenities = map['amenities'];
    final List<String> parsedAmenities;

    if (rawAmenities is List) {
      parsedAmenities =
          rawAmenities.map((item) => item.toString()).toList();
    } else if (rawAmenities is String &&
        rawAmenities.trim().isNotEmpty) {
      parsedAmenities = rawAmenities
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    } else {
      parsedAmenities = [];
    }

    final rawPhotos = map['room_photo'];
    final photos = <Map<String, dynamic>>[];

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

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateA.compareTo(dateB);
    });

    final photoUrls = photos
        .map((photo) => photo['photo_url']?.toString().trim() ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

    return Room(
      id: map['id']?.toString() ?? '',
      propertyId: map['property_id']?.toString() ?? '',
      roomNumber: map['room_number']?.toString() ?? '',
      roomType: map['room_type']?.toString() ?? 'Room',
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
