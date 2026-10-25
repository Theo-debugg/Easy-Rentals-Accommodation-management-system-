import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/view_models/rooms_view_model.dart';
import 'package:easy_rentals_mobile_app/views/property/room_details_screen.dart';

class PropertiesTab extends StatefulWidget {
  const PropertiesTab({super.key});

  @override
  State<PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends State<PropertiesTab> {
  int _selectedFilter = 0;
  final List<String> _filters = ['Available', 'Occupied'];
  final TextEditingController _searchController = TextEditingController();

  // Temporary testing mode: the ASP.NET rooms API is not connected yet.
  static const bool _useEmptyRoomsForTesting = true;

  final RoomsViewModel _roomsViewModel = const RoomsViewModel();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search here...',
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
              ),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_filters.length, (index) {
              final isSelected = _selectedFilter == index;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_filters[index]),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedFilter = index);
                  },
                  selectedColor: AppTheme.buttonColor,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.black87,
                    fontSize: 12,
                  ),
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.buttonColor
                        : Colors.grey,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _useEmptyRoomsForTesting
                ? _buildEmptyRoomsMessage()
                : _buildRoomList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRoomsMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: AppTheme.buttonColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'No rooms available yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rooms will appear here once they have been '
              'added to the system. Please check back soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomList() {
    final filteredRooms = _roomsViewModel.filter(
      query: _searchController.text,
      status: _filters[_selectedFilter],
    );

    if (filteredRooms.isEmpty) {
      return const Center(
        child: Text('No properties match your search.'),
      );
    }

    return ListView.separated(
      itemCount: filteredRooms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final room = filteredRooms[index];

        return _PropertyCard(
          title: room.title,
          details:
              '${room.suburb}\n'
              '${room.bedrooms} beds • ${room.bathrooms} bath\n'
              'R${room.monthlyRent.toString().replaceAllMapped(
                RegExp(r'(?=(\d{3})+$)'),
                (_) => ',',
              )}',
          status: room.status,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RoomDetailsScreen(),
              ),
            );
          },
        );
      },
    );
  }
}
class _PropertyCard extends StatelessWidget {
  final String title;
  final String details;
  final String status;
  final VoidCallback onTap;

  const _PropertyCard({
    required this.title,
    required this.details,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.meeting_room_outlined,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: status == 'Available'
                    ? Colors.green
                    : Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}