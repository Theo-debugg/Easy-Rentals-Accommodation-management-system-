import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/Models/room.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/ViewModels/rooms_view_model.dart';
import 'package:easy_rentals_mobile_app/Views/property/room_details_screen.dart';

/// The "Properties" tab of [MainShell].
///
/// Loads all rooms via [RoomsViewModel], shows a search box and an
/// availability filter (Available / Occupied), and renders each room as a
/// tappable card that opens [RoomDetailsScreen].
class PropertiesTab extends StatefulWidget {
  const PropertiesTab({super.key});

  @override
  State<PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends State<PropertiesTab> {
  // Filter selection is tracked by index into [_filters].
  int _selectedFilter = 0;

  // Filter labels; the value here is compared against each room's status.
  final List<String> _filters = ['Available', 'Occupied'];

  // Search box controller; changes trigger a rebuild so [filter] runs again.
  final TextEditingController _searchController =
      TextEditingController();

  // View model that fetches rooms and performs filtering.
  final RoomsViewModel _roomsViewModel = RoomsViewModel();

  // Loaded rooms.
  List<Room> _rooms = [];

  // Loading / error flags.
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

  /// Loads all rooms via [RoomsViewModel.fetchRooms].
  ///
  /// Clears any previous error and toggles the loading flag around the fetch.
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

          // Search field. `onChanged` triggers a rebuild so filtering re-runs.
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
              // Borderless pill matching the app's input style.
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 16),

          // Availability filter chips (single-select).
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
                  // Branded purple fill + white text when selected.
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

          // Main content area: loading / error / empty / list.
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  /// Dispatches to the correct content widget based on state.
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state with a retry button.
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

    // No rooms at all.
    if (_rooms.isEmpty) {
      return _buildEmptyRoomsMessage();
    }

    return _buildRoomList();
  }

  /// Empty-state widget (no rooms in the system) with a refresh action.
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

  /// Populated room list with search + status filtering and pull-to-refresh.
  Widget _buildRoomList() {
    // Apply the current search text and filter to produce the visible rooms.
    final filteredRooms = _roomsViewModel.filter(
      _rooms,
      query: _searchController.text,
      status: _filters[_selectedFilter],
    );

    // Nothing matches the current search/filter combination.
    if (filteredRooms.isEmpty) {
      return const Center(
        child: Text('No rooms match your search or filter.'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRooms,
      child: ListView.separated(
        // Always scrollable so pull-to-refresh works even when short.
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: filteredRooms.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final room = filteredRooms[index];
          debugPrint('ROOM: ${room.roomNumber}');
          debugPrint('PHOTO URL: ${room.photoUrl}');

          // Compose the multiline card details from the room's fields.
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
            photoUrl: room.photoUrl,
            // Navigate to the full details screen for this room.
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

/// A single-room summary card used by [PropertiesTab].
///
/// Shows a thumbnail, title, details text, and a coloured availability pill.
class _PropertyCard extends StatelessWidget {
  /// Primary card title (typically the room type).
  final String title;

  /// Multiline description shown under the title.
  final String details;

  /// Availability label (e.g. "Available", "Occupied").
  final String status;

  /// Optional URL for the room photo; falls back to a placeholder.
  final String? photoUrl;

  /// Tap handler (opens the room details screen).
  final VoidCallback onTap;

  const _PropertyCard({
    required this.title,
    required this.details,
    required this.status,
    required this.photoUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Green pill for available rooms, orange for everything else.
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fixed-size rounded thumbnail.
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: _buildRoomImage(),
              ),
            ),
            const SizedBox(width: 16),

            // Title + details block (expands to fill available width).
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

            // Availability pill.
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

  /// Builds the thumbnail: network image when a URL is present, otherwise a
  /// placeholder. Shows a spinner while downloading and falls back to the
  /// placeholder on error.
  Widget _buildRoomImage() {
    final url = photoUrl?.trim();

    if (url == null || url.isEmpty) {
      return _imagePlaceholder();
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: 80,
      height: 80,
      loadingBuilder: (context, child, loadingProgress) {
        // `loadingProgress == null` means the image has finished loading.
        if (loadingProgress == null) return child;

        return Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _imagePlaceholder();
      },
    );
  }

  /// Grey placeholder with a room icon, used when no image is available.
  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade400,
      alignment: Alignment.center,
      child: const Icon(
        Icons.meeting_room_outlined,
        size: 32,
        color: Colors.white,
      ),
    );
  }
}