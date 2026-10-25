class Room {
  final String id;
  final String title;
  final String address;
  final String suburb;
  final int bedrooms;
  final int bathrooms;
  final int monthlyRent;
  final String status;

  const Room({required this.id, required this.title, required this.address, required this.suburb, required this.bedrooms, required this.bathrooms, required this.monthlyRent, required this.status});

  bool get isAvailable => status.toLowerCase() == 'available';
}
