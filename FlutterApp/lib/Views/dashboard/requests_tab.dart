import 'package:flutter/material.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';
import 'package:easy_rentals_mobile_app/ViewModels/requests_view_model.dart';
import 'package:easy_rentals_mobile_app/Models/viewing_request.dart';

/// The "My Requests" tab of [MainShell].
///
/// Renders the current user's viewing requests from the shared
/// [RequestsViewModel] singleton and lets them cancel individual requests
/// (with a confirmation dialog).
class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  @override
  void initState() {
    super.initState();
    // Refresh from Supabase so the cached list is up-to-date on first view.
    RequestsViewModel.instance.refreshFromSupabase();
  }

  /// Cancels a viewing request after confirming with the user.
  ///
  /// - Fails gracefully when the request has no database ID.
  /// - Uses a confirmation dialog to avoid accidental cancellation.
  /// - On success, shows a snackbar; on failure, shows the error.
  Future<void> _cancelRequest(ViewingRequest request) async {
    // Check that the request has a database ID.
    if (request.id == null || request.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This request has no database ID.'),
        ),
      );
      return;
    }

    // Ask the user to confirm cancellation.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text(
          'Are you sure you want to cancel this viewing request?',
        ),
        actions: [
          // Dismiss the dialog with `false` ("keep").
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep Request'),
          ),
          // Dismiss with `true` ("confirm cancel").
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );

    // User dismissed the dialog or chose "Keep Request".
    if (confirmed != true || !mounted) return;

    try {
      await RequestsViewModel.instance.deleteRequest(request.id!);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Viewing request cancelled successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not cancel request: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever the shared RequestsViewModel notifies.
    return ListenableBuilder(
      listenable: RequestsViewModel.instance,
      builder: (context, _) {
        final requests = RequestsViewModel.instance.requests;

        // Empty state.
        if (requests.isEmpty) {
          return const Center(
            child: Text('No requests yet'),
          );
        }

        // Populated list — one card per request.
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final r = requests[index];

            return _RequestCard(
              title: r.propertyTitle,
              subtitle: r.room,
              // Combine date and time into a single line.
              date: 'Date: ${r.date} | ${r.time}',
              status: r.status,
              onCancel: () => _cancelRequest(r),
            );
          },
        );
      },
    );
  }
}

/// A single viewing-request card used by [RequestsTab].
class _RequestCard extends StatelessWidget {
  /// Property title shown as the primary line.
  final String title;

  /// Room identifier shown under the title.
  final String subtitle;

  /// Pre-formatted date + time line.
  final String date;

  /// Status string (approved / review / cancelled / other).
  final String status;

  /// Tap handler for the "Cancel Request" button.
  final VoidCallback onCancel;

  const _RequestCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.status,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Pick a status colour based on the status string.
    final Color statusColor;

    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'review':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title + status pill.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title takes the remaining width; status pill sits on the right.
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
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
          const SizedBox(height: 4),

          // Room identifier.
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Date + time line.
          Text(
            date,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Cancel button aligned to the trailing edge.
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Request'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}