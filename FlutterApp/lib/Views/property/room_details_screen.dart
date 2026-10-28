
import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/Models/room.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_bottom_nav.dart';
import 'package:easy_rentals_mobile_app/Views/shared/custom_button.dart';
import 'package:easy_rentals_mobile_app/Views/property/booking_appointment_screen.dart';
import 'package:easy_rentals_mobile_app/Views/dashboard/main_shell.dart';
import 'package:easy_rentals_mobile_app/Views/enquiries/send_enquiry_screen.dart';
//import 'package:easy_rentals_mobile_app/Widgets/room_photo_slider.dart';

class RoomDetailsScreen extends StatelessWidget {
  final Room room;

  const RoomDetailsScreen({
    super.key,
    required this.room,
  });

  String get _roomTitle {
    final type = room.roomType.trim();
    final number = room.roomNumber.trim();

    if (type.isEmpty && number.isEmpty) return 'Room details';
    if (type.isEmpty) return 'Room $number';
    if (number.isEmpty) return type;

    return '$type — Room $number';
  }

  String get _formattedPrice {
    final price = room.price;
    final value = price.toStringAsFixed(2);
    final parts = value.split('.');
    final wholeNumber = parts[0];
    final decimals = parts.length > 1 ? parts[1] : '00';

    final formattedWholeNumber = wholeNumber.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );

    final formattedDecimals =
        decimals == '00' ? '' : '.$decimals';

    return 'R$formattedWholeNumber$formattedDecimals per month';
  }

  Widget _buildRoomImage() {
    final url = room.photoUrl?.trim();

    if (url == null || url.isEmpty) {
      return _imagePlaceholder();
    }

    return Image.network(
      url,
      width: double.infinity,
      height: 220,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Container(
          height: 220,
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _imagePlaceholder();
      },
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.grey.shade300,
      alignment: Alignment.center,
      child: const Icon(
        Icons.meeting_room_outlined,
        size: 64,
        color: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final description = room.description.trim();
    final amenities = room.amenities;

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
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: double.infinity,
                height: 220,
                child: _buildRoomImage(),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              _roomTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              _formattedPrice,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

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
                    isOutlined: true,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SendEnquiryScreen(
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
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
        onTap: (index) => MainShell.goToTab(context, index),
      ),
    );
  }
}
