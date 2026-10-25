import 'package:easy_rentals_mobile_app/models/room.dart';

class RoomsViewModel {
  const RoomsViewModel();
  static const List<Room> rooms = [
    Room(id: 'park-west-1', title: '20 Steven Street, Park West', address: '20 Steven Street, Park West', suburb: 'Blenheim', bedrooms: 4, bathrooms: 2, monthlyRent: 12000, status: 'Available'),
    Room(id: 'park-west-2', title: '20 Steven Street, Park West', address: '20 Steven Street, Park West', suburb: 'Blenheim', bedrooms: 4, bathrooms: 2, monthlyRent: 12000, status: 'Occupied'),
    Room(id: 'park-west-3', title: '20 Steven Street, Park West', address: '20 Steven Street, Park West', suburb: 'Blenheim', bedrooms: 4, bathrooms: 2, monthlyRent: 12000, status: 'Available'),
  ];

  List<Room> filter({String query = '', String status = 'Available'}) => rooms.where((room) {
    final matchesQuery = '${room.title} ${room.suburb} ${room.address}'.toLowerCase().contains(query.trim().toLowerCase());
    final matchesStatus = status == 'All' || room.status.toLowerCase() == status.toLowerCase();
    return matchesQuery && matchesStatus;
  }).toList(growable: false);
}
