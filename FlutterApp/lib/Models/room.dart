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
  });

  bool get isAvailable =>
      availability.trim().toLowerCase() == 'available';

  factory Room.fromMap(Map<String, dynamic> map) {
    final rawAmenities = map['amenities'];

    final List<String> parsedAmenities;
    if (rawAmenities is List) {
      parsedAmenities = rawAmenities
          .map((item) => item.toString())
          .toList();
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
    );
  }
}