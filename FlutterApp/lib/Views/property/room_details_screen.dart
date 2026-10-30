import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/Models/room.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_bottom_nav.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_button.dart';
import 'package:easy_rentals_mobile_app/Views/property/booking_appointment_screen.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/main_shell.dart';
import 'package:easy_rentals_mobile_app/Views/enquiries/send_enquiry_screen.dart';
import 'package:easy_rentals_mobile_app/Views/Widgets/room_photo_slider.dart';

/// Read-only detail view for a single room.
///
/// Shows a photo carousel, title, price, availability, description, and
/// amenity chips, plus two primary actions:
/// - "Request Viewing" → [BookingAppointmentScreen]
/// - "Send Enquiry" → [SendEnquiryScreen]
///
/// This screen is stateless: it renders whatever the supplied [Room] contains.
class RoomDetailsScreen extends StatelessWidget {
  /// The room being displayed.
  final Room room;

  const RoomDetailsScreen({
    super.key,
    required this.room,
  });

  /// Builds a human-readable title from the room's type and number.
  ///
  /// Falls back gracefully when either field is missing:
  /// - "Room details" if both are blank
  /// - "Room <number>" if only the type is blank
  /// - "<type>" if only the number is blank
  /// - "<type> — Room <number>" otherwise
  String get _roomTitle {
    final type = room.roomType.trim();
    final number = room.roomNumber.trim();

    if (type.isEmpty && number.isEmpty) return 'Room details';
    if (type.isEmpty) return 'Room $number';
    if (number.isEmpty) return type;

    return '$type — Room $number';
  }

  /// Formats [room.price] as e.g. "R1,234.50 per month".
  ///
  /// Inserts thousands separators via a regex, and omits the decimal part
  /// when it is exactly "00" (so "R1,200 per month", not "R1,200.00 ...").
  String get _formattedPrice {
    final price = room.price;
    final value = price.toStringAsFixed(2);
    final parts = value.split('.');
    final wholeNumber = parts[0];
    final decimals = parts.length > 1 ? parts[1] : '00';

    // \B(?=(\d{3})+(?!\d)) matches positions that precede groups of 3 digits
    // but aren't the very start of the string.
    final formattedWholeNumber = wholeNumber.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

    final formattedDecimals =
        decimals == '00' ? '' : '.$decimals';

    return 'R$formattedWholeNumber$formattedDecimals per month';
  }

  /// Builds the room's photo carousel at a fixed height.
  ///
  /// Relies on [RoomPhotoSlider] to handle empty / loading / error states.
  Widget _buildRoomImage() {
    return RoomPhotoSlider(
      photoUrls: room.photoUrls,
      height: 220,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pre-trim fields once so the widget tree stays free of repeated
    // string manipulation.
    final description = room.description.trim();
    final amenities = room.amenities;

    // Default to "Unknown" so the availability pill always has text.
    final availability = room.availability.trim().isEmpty
        ? 'Unknown'
        : room.availability.trim();

    final isAvailable =
        availability.toLowerCase() == 'available';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Room details',
          style: TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo carousel with rounded corners.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildRoomImage(),
            ),
            const SizedBox(height: 16),

            // Title (type + room number).
            Text(
              _roomTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Formatted monthly price.
            Text(
              _formattedPrice,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Availability pill: green background for available, orange
            // otherwise. Uses a lower-alpha tint so the label stays legible.
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isAvailable
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                availability,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAvailable
                      ? Colors.green[800]
                      : Colors.orange[900],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Description section (with fallback text when empty).
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              description.isNotEmpty
                  ? description
                  : 'No description has been added for this room yet.',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),

            // Amenities section — rendered only when the list is non-empty.
            if (amenities.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Amenities',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              // Wrap flows chips onto new lines as space runs out.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: amenities.map((amenity) {
                  return Chip(
                    avatar: const Icon(
                      Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(amenity),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 28),

            // Primary actions: request a viewing or send an enquiry. The two
            // buttons share the row via Expanded so they always split space
            // evenly, with a 12px gap between them.
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Request Viewing',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingAppointmentScreen(
                            // Forward this room's title/property id so the
                            // booking screen can load the right rooms.
                            propertyTitle: _roomTitle,
                            propertyAddress:
                                'Property ID: ${room.propertyId}',
                            propertyId: room.propertyId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Send Enquiry',
                    // Outlined variant to visually distinguish it from the
                    // primary "Request Viewing" action.
                    isOutlined: true,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SendEnquiryScreen(
                            // Pre-fill the enquiry subject with this room.
                            initialSubject:
                                'Enquiry about $_roomTitle',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // "Properties" is index 1 in the shared bottom nav.
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) => MainShell.goToTab(context, index),
      ),
    );
  }
}