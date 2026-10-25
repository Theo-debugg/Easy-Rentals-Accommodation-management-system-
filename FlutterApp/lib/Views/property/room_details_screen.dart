import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/views/shared/custom_bottom_nav.dart';
import 'package:easy_rentals_mobile_app/views/shared/custom_button.dart';
import 'package:easy_rentals_mobile_app/views/property/booking_appointment_screen.dart';
import 'package:easy_rentals_mobile_app/views/dashboard/main_shell.dart';
import 'package:easy_rentals_mobile_app/views/enquiries/send_enquiry_screen.dart';

class RoomDetailsScreen extends StatelessWidget {
  const RoomDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Room details', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 64, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Easy Rental Student\nAccommodation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'R3,500 month',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Park Road, Bloemfontein',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Single bedroom, self catering with kitchen area. '
              'Free Wi-Fi. Laundry. Security.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Request Viewing',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookingAppointmentScreen(
                            propertyTitle: 'Easy Rental Student Accommodation',
                            propertyAddress: 'Park Road, Bloemfontein',
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
                          builder: (_) => const SendEnquiryScreen(
                            initialSubject:
                                'Enquiry about Easy Rental Student Accommodation',
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