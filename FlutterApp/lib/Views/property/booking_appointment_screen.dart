import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Models/appointment.dart';
import 'package:easy_rentals_mobile_app/ViewModels/requests_view_model.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_bottom_nav.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_button.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/main_shell.dart';

/// Lets a signed-in student request a viewing for a specific room.
///
/// The screen loads the property's rooms from Supabase, lets the user pick an
/// available room, a preferred date, and a preferred time slot, then submits
/// an [Appointment] via [RequestsViewModel].
class BookingAppointmentScreen extends StatefulWidget {
  /// Display title of the property (shown at the top of the screen).
  final String propertyTitle;

  /// Display address / subtitle of the property.
  final String propertyAddress;

  /// Supabase `property.id` used to fetch the property's rooms.
  final String propertyId;

  const BookingAppointmentScreen({
    super.key,
    required this.propertyId,
    this.propertyTitle = '20 Steven Street, Park West',
    this.propertyAddress = 'Blenheim',
  });

  @override
  State<BookingAppointmentScreen> createState() =>
      _BookingAppointmentScreenState();
}

class _BookingAppointmentScreenState
    extends State<BookingAppointmentScreen> {
  // Shared Supabase client used for both the room query and auth checks.
  final SupabaseClient _supabase = Supabase.instance.client;

  // Rooms belonging to the current property (raw row maps).
  List<Map<String, dynamic>> _rooms = [];

  // Index into [_rooms] of the currently selected room, if any.
  int? _selectedRoomIndex;

  // Loading / error flags for the room-fetch phase.
  bool _roomsLoading = true;
  String? _roomsError;

  // Fixed time slots the user can choose from.
  final List<String> _times = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 03:00 PM',
    '04:00 PM - 05:00 PM',
  ];

  // Index into [_times] of the selected slot.
  int? _selectedTimeIndex;

  // Selected viewing date; `null` until the user picks one.
  DateTime? _selectedDate;

  // True while the viewing request is being submitted (disables the button
  // and changes its label to "Submitting...").
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Kick off the room query as soon as the screen is created.
    _loadRooms();
  }

  /// Loads the rooms for [widget.propertyId] from Supabase.
  ///
  /// On success, auto-selects the first available room (if any) and clears
  /// the error. On failure, stores the error message for the retry UI.
  Future<void> _loadRooms() async {
    try {
      final response = await _supabase
          .from('room')
          .select(
            // Only fetch the columns the UI actually needs.
            'id, property_id, room_number, room_type, price, '
            'description, availability, amenities, staff_id',
          )
          .eq('property_id', widget.propertyId)
          .order('room_number');

      // Normalise each row into a mutable map for safe access below.
      final rooms = (response as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      // The widget may have been popped while the query was in-flight.
      if (!mounted) return;

      setState(() {
        _rooms = rooms;

        // Pre-select the first room marked as available, if any.
        final firstAvailable = _rooms.indexWhere(_isAvailable);
        _selectedRoomIndex =
            firstAvailable >= 0 ? firstAvailable : null;

        _roomsLoading = false;
        _roomsError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        // Keep the error as a string so it can be shown verbatim.
        _roomsError = e.toString();
        _roomsLoading = false;
      });
    }
  }

  /// Returns `true` when the room's `availability` column is "available"
  /// (case-insensitive, trimmed). Missing/blank values count as unavailable.
  bool _isAvailable(Map<String, dynamic> room) {
    return (room['availability']?.toString().trim().toLowerCase() ??
            '') ==
        'available';
  }

  /// Formats a price value (num or numeric string) as "R<amount> per month".
  ///
  /// Falls back to `0.0` if the value can't be parsed.
  String _money(dynamic value) {
    final price = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0.0;

    return 'R${price.toStringAsFixed(2)} per month';
  }

  /// Opens a date picker limited to today through one year from today.
  ///
  /// Stores the picked date in [_selectedDate] via `setState`.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    // Normalise to midnight so "today" is selectable regardless of the time.
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  /// Human-readable version of [_selectedDate] (e.g. "Jan 15, 2025").
  ///
  /// Returns an empty string when no date is selected yet.
  String get _formattedDate {
    if (_selectedDate == null) return '';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[_selectedDate!.month - 1]} '
        '${_selectedDate!.day}, ${_selectedDate!.year}';
  }

  /// Validates the form and submits the viewing request.
  ///
  /// Validation order:
  /// 1. Rooms must have finished loading.
  /// 2. A room must be selected and marked available.
  /// 3. A date must be picked.
  /// 4. A time slot must be picked.
  /// 5. A user must be signed in.
  ///
  /// On success: shows a confirmation dialog; OK pops back to the previous
  /// screen. On failure: shows a snackbar with the error.
  Future<void> _submit() async {
    // 1. Rooms still loading — ask the user to wait.
    if (_roomsLoading) {
      _showMessage('Please wait while rooms are loading.');
      return;
    }

    // 2. Room must be selected, in-range, and still available.
    if (_selectedRoomIndex == null ||
        _selectedRoomIndex! >= _rooms.length ||
        !_isAvailable(_rooms[_selectedRoomIndex!])) {
      _showMessage('Please select an available room.');
      return;
    }

    // 3. Date is required.
    if (_selectedDate == null) {
      _showMessage('Please select a preferred date first.');
      return;
    }

    // 4. Time slot is required.
    if (_selectedTimeIndex == null) {
      _showMessage('Please select a preferred time.');
      return;
    }

    // 5. Submission is tied to the authenticated user.
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage('Please sign in before requesting a viewing.');
      return;
    }

    // Everything checks out — resolve the selected room row.
    final selectedRoom = _rooms[_selectedRoomIndex!];

    setState(() => _isLoading = true);

    try {
      // Delegate to the shared RequestsViewModel singleton, which inserts
      // the row and updates its local cache.
      await RequestsViewModel.instance.submit(
        Appointment(
          userId: user.id,
          propertyTitle: widget.propertyTitle,
          propertyAddress: widget.propertyAddress,
          // Room label like "Room 12"; `.trim()` avoids stray whitespace
          // when `room_number` is missing.
          room: 'Room ${selectedRoom['room_number'] ?? ''}'.trim(),
          roomId: selectedRoom['id'].toString(),
          viewingDate: _selectedDate!,
          viewingTime: _times[_selectedTimeIndex!],
          status: 'pending',
        ),
      );

      if (!mounted) return;

      // Confirmation dialog; OK closes it and pops this screen.
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Request Submitted'),
          content: const Text(
            'Your viewing request has been submitted successfully. '
            'We will contact you shortly with confirmation details.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // Any error from the insert (including RLS failures) is shown here.
      if (mounted) {
        _showMessage('Failed to submit request: $e');
      }
    } finally {
      // Always re-enable the button, unless the widget was disposed.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Shows a snackbar with [message].
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Builds the "Select room" section, handling loading / error / empty /
  /// populated states.
  Widget _buildRoomsSection() {
    // Loading state.
    if (_roomsLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Error state with a retry button that resets flags and re-fetches.
    if (_roomsError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Could not load rooms from Supabase.'),
          const SizedBox(height: 4),
          Text(
            _roomsError!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _roomsLoading = true;
                _roomsError = null;
              });
              _loadRooms();
            },
            child: const Text('Try again'),
          ),
        ],
      );
    }

    // No rooms found for this property.
    if (_rooms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No rooms were found for this property.'),
      );
    }

    // Populated state: one selectable card per room.
    return Column(
      children: List.generate(_rooms.length, (index) {
        final room = _rooms[index];
        final isSelected = _selectedRoomIndex == index;
        final available = _isAvailable(room);

        // Resolve display values with sensible fallbacks.
        final number =
            room['room_number']?.toString() ?? 'Unnamed';
        final type = room['room_type']?.toString() ?? 'Room';
        final status =
            room['availability']?.toString() ?? 'Unknown';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            // Only available rooms are tappable.
            onTap: available
                ? () => setState(
                      () => _selectedRoomIndex = index,
                    )
                : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // Highlight border when selected.
                border: Border.all(
                  color: isSelected
                      ? AppTheme.buttonColor
                      : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Radio indicator reflects selection state.
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppTheme.buttonColor
                        : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  // Room details (number, type, price, optional description).
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room $number',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          type,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          _money(room['price']),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        // Only render the description when non-blank.
                        if ((room['description']?.toString() ?? '')
                            .trim()
                            .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              room['description'].toString(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Availability pill (green = available, orange = other).
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: available
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
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Book Viewing Appointment',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Scrollable so the form fits on smaller screens.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property title + address header.
            Text(
              '${widget.propertyTitle}\n${widget.propertyAddress}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Room picker section.
            const Text(
              'Select room',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildRoomsSection(),
            const SizedBox(height: 16),

            // Date picker (tap opens the calendar dialog).
            const Text(
              'Select Preferred Time Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    // Placeholder vs. formatted date text.
                    Text(
                      _selectedDate == null
                          ? 'Select a date (YYYY-MM-DD)'
                          : _formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedDate == null
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Time slot picker: one tile per entry in [_times].
            const Text(
              'Select Preferred Time:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(_times.length, (index) {
              final isSelected = _selectedTimeIndex == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedTimeIndex = index);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      // Selected tiles get a filled brand background.
                      color: isSelected
                          ? AppTheme.buttonColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      _times[index],
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // Submit button; disabled while the request is in-flight.
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                text: _isLoading
                    ? 'Submitting...'
                    : 'Submit Viewing Request',
                onPressed: _isLoading ? null : _submit,
              ),
            ),
          ],
        ),
      ),

      // "My Requests" is index 2 in the shared bottom nav.
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) => MainShell.goToTab(context, index),
      ),
    );
  }
}