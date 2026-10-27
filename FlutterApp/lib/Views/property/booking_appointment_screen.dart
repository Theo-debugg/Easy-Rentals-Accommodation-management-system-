
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Models/appointment.dart';
import 'package:easy_rentals_mobile_app/ViewModels/requests_view_model.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_bottom_nav.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_button.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/main_shell.dart';

class BookingAppointmentScreen extends StatefulWidget {
  final String propertyTitle;
  final String propertyAddress;
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
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _rooms = [];
  int? _selectedRoomIndex;
  bool _roomsLoading = true;
  String? _roomsError;

  final List<String> _times = [
    '09:00 AM - 10:00 AM',
    '10:00 AM - 03:00 PM',
    '04:00 PM - 05:00 PM',
  ];

  int? _selectedTimeIndex;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final response = await _supabase
          .from('room')
          .select(
            'id, property_id, room_number, room_type, price, '
            'description, availability, amenities, staff_id',
          )
          .eq('property_id', widget.propertyId)
          .order('room_number');

      final rooms = (response as List)
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      if (!mounted) return;

      setState(() {
        _rooms = rooms;

        final firstAvailable = _rooms.indexWhere(_isAvailable);
        _selectedRoomIndex =
            firstAvailable >= 0 ? firstAvailable : null;

        _roomsLoading = false;
        _roomsError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _roomsError = e.toString();
        _roomsLoading = false;
      });
    }
  }

  bool _isAvailable(Map<String, dynamic> room) {
    return (room['availability']?.toString().trim().toLowerCase() ??
            '') ==
        'available';
  }

  String _money(dynamic value) {
    final price = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0.0;

    return 'R${price.toStringAsFixed(2)} per month';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
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

  Future<void> _submit() async {
    if (_roomsLoading) {
      _showMessage('Please wait while rooms are loading.');
      return;
    }

    if (_selectedRoomIndex == null ||
        _selectedRoomIndex! >= _rooms.length ||
        !_isAvailable(_rooms[_selectedRoomIndex!])) {
      _showMessage('Please select an available room.');
      return;
    }

    if (_selectedDate == null) {
      _showMessage('Please select a preferred date first.');
      return;
    }

    if (_selectedTimeIndex == null) {
      _showMessage('Please select a preferred time.');
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      _showMessage('Please sign in before requesting a viewing.');
      return;
    }

    final selectedRoom = _rooms[_selectedRoomIndex!];

    setState(() => _isLoading = true);

    try {
      await RequestsViewModel.instance.submit(
        Appointment(
          userId: user.id,
          propertyTitle: widget.propertyTitle,
          propertyAddress: widget.propertyAddress,
          room: 'Room ${selectedRoom['room_number'] ?? ''}'.trim(),
          roomId: selectedRoom['id'].toString(),
          viewingDate: _selectedDate!,
          viewingTime: _times[_selectedTimeIndex!],
          status: 'pending',
        ),
      );

      if (!mounted) return;

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
      if (mounted) {
        _showMessage('Failed to submit request: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildRoomsSection() {
    if (_roomsLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

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

    if (_rooms.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No rooms were found for this property.'),
      );
    }

    return Column(
      children: List.generate(_rooms.length, (index) {
        final room = _rooms[index];
        final isSelected = _selectedRoomIndex == index;
        final available = _isAvailable(room);

        final number =
            room['room_number']?.toString() ?? 'Unnamed';
        final type = room['room_type']?.toString() ?? 'Room';
        final status =
            room['availability']?.toString() ?? 'Unknown';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
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
                border: Border.all(
                  color: isSelected
                      ? AppTheme.buttonColor
                      : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? AppTheme.buttonColor
                        : Colors.grey,
                  ),
                  const SizedBox(width: 10),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.propertyTitle}\n${widget.propertyAddress}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
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
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        onTap: (index) => MainShell.goToTab(context, index),
      ),
    );
  }
}
