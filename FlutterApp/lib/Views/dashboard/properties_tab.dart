import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/Models/room.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/ViewModels/rooms_view_model.dart';
import 'package:easy_rentals_mobile_app/Views/property/room_details_screen.dart';

class PropertiesTab extends StatefulWidget {
  const PropertiesTab({super.key});

  @override
  State<PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends State<PropertiesTab> {
  int _selectedFilter = 0;
  final List<String> _filters = ['Available', 'Occupied'];
  final TextEditingController _searchController =
      TextEditingController();

  final RoomsViewModel _roomsViewModel = RoomsViewModel();

  List<Room> _rooms = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final rooms = await _roomsViewModel.fetchRooms();

      if (!mounted) return;

      setState(() {
        _rooms = rooms;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search rooms...',
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
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: Colors.grey,
              ),
              const SizedBox(height: 12),
              const Text(
                'Could not load rooms',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRooms,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rooms.isEmpty) {
      return _buildEmptyRoomsMessage();
    }

    return _buildRoomList();
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
              'Rooms added to the system will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadRooms,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh rooms'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomList() {
    final filteredRooms = _roomsViewModel.filter(
      _rooms,
      query: _searchController.text,
      status: _filters[_selectedFilter],
    );

    if (filteredRooms.isEmpty) {
      return const Center(
        child: Text('No rooms match your search or filter.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRooms,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredRooms.length,
        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final room = filteredRooms[index];

          final details = [
            room.roomType,
            'Room ${room.roomNumber}',
            'R${room.price} per month',
            if (room.description.isNotEmpty)
              room.description,
            if (room.amenities.isNotEmpty)
              'Amenities: ${room.amenities.join(', ')}',
          ].join('\n');

          return _PropertyCard(
            title: room.roomType,
            details: details,
            status: room.availability,
            onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RoomDetailsScreen(room: room),
    ),
  );
},
          );
        },
      ),
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
    final isAvailable =
        status.trim().toLowerCase() == 'available';

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
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isAvailable
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