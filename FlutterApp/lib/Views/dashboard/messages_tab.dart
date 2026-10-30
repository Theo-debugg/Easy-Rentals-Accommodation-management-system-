import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';

/// Displays the current student's enquiries and, once one is opened, the
/// full message thread with staff replies.
///
/// Two modes:
/// - **List mode** — a scrollable list of the student's enquiries.
/// - **Conversation mode** — a threaded view of a single enquiry, including
///   the original enquiry body, staff replies, and follow-up messages the
///   student can send.
class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  // Shared Supabase client for all reads/writes in this tab.
  final SupabaseClient _supabase = Supabase.instance.client;

  // Composer controller for follow-up messages.
  final TextEditingController _messageController =
      TextEditingController();

  // Scrolls the conversation list to the bottom after load/send.
  final ScrollController _scrollController = ScrollController();

  // Enquiries belonging to the current student (list mode).
  List<Map<String, dynamic>> _enquiries = [];

  // Message thread for [_selectedEnquiry] (conversation mode), including the
  // synthesised "original enquiry" entry prepended in [_loadMessages].
  List<Map<String, dynamic>> _messages = [];

  // The enquiry currently open in conversation mode; `null` in list mode.
  Map<String, dynamic>? _selectedEnquiry;

  // Loading / in-flight flags for the various async operations.
  bool _loadingEnquiries = true;
  bool _loadingMessages = false;
  bool _sending = false;
  bool _updatingStatus = false;

  // Error text shown when the enquiry list fails to load.
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEnquiries();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Formats a Supabase timestamp as `dd/MM/yyyy HH:mm` in local time.
  ///
  /// Returns an empty string for `null` or unparseable values.
  String _formatDate(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return '';

    final localDate = date.toLocal();

    return '${localDate.day.toString().padLeft(2, '0')}/'
        '${localDate.month.toString().padLeft(2, '0')}/'
        '${localDate.year} '
        '${localDate.hour.toString().padLeft(2, '0')}:'
        '${localDate.minute.toString().padLeft(2, '0')}';
  }

  /// Loads the current student's enquiries from Supabase.
  ///
  /// - If signed out, shows an auth error.
  /// - On success, refreshes [_enquiries] and re-resolves [_selectedEnquiry]
  ///   by `ReferenceNo` so any open conversation keeps up-to-date status.
  Future<void> _loadEnquiries() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      if (!mounted) return;

      setState(() {
        _loadingEnquiries = false;
        _error = 'Please log in to view your messages.';
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loadingEnquiries = true;
        _error = null;
      });
    }

    try {
      // Fetch only this student's enquiries, newest first.
      final response = await _supabase
          .from('enquiries')
          .select()
          .eq('student_id', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _enquiries = List<Map<String, dynamic>>.from(response);
        _loadingEnquiries = false;

        // Refresh the selected enquiry after reloading.
        if (_selectedEnquiry != null) {
          final referenceNo = _selectedEnquiry!['ReferenceNo'];

          // Find the same enquiry in the freshly-loaded list.
          final updatedEnquiries = _enquiries.where(
            (enquiry) => enquiry['ReferenceNo'] == referenceNo,
          );

          if (updatedEnquiries.isNotEmpty) {
            _selectedEnquiry = updatedEnquiries.first;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingEnquiries = false;
        _error = 'Could not load enquiries. Please try again.';
      });

      debugPrint('Load enquiries error: $e');
    }
  }

  /// Opens the given [enquiry] in conversation mode and loads its messages.
  Future<void> _openEnquiry(
    Map<String, dynamic> enquiry,
  ) async {
    setState(() {
      _selectedEnquiry = enquiry;
      _messages = [];
      _loadingMessages = true;
    });

    await _loadMessages();
  }

  /// Loads the message thread for the currently selected enquiry.
  ///
  /// The original enquiry body is prepended (flagged with
  /// `is_original_enquiry: true`) so it renders as the first bubble in the
  /// conversation. Subsequent rows come from `enquiry_messages`.
  ///
  /// After loading, scrolls to the bottom so the newest message is visible.
  Future<void> _loadMessages() async {
    final enquiry = _selectedEnquiry;

    if (enquiry == null) return;

    try {
      final referenceNo = enquiry['ReferenceNo'];

      // Fetch follow-up messages, oldest first.
      final response = await _supabase
          .from('enquiry_messages')
          .select()
          .eq('enquiry_ReferenceNo', referenceNo)
          .order('created_at', ascending: true);

      if (!mounted) return;

      // Start with the original enquiry message.
      final allMessages = <Map<String, dynamic>>[];

      final originalMessage =
          (enquiry['message'] ?? '').toString().trim();

      if (originalMessage.isNotEmpty) {
        allMessages.add({
          'message': originalMessage,
          'student_id': enquiry['student_id'],
          'staff_id': null,
          'created_at': enquiry['created_at'],
          'is_original_enquiry': true,
        });
      }

      // Add all subsequent student and staff messages.
      allMessages.addAll(
        List<Map<String, dynamic>>.from(response),
      );

      setState(() {
        _messages = allMessages;
        _loadingMessages = false;
      });

      // Scroll to the bottom once the list has been laid out.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(
            _scrollController.position.maxScrollExtent,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingMessages = false;
      });

      _showMessage('Could not load this conversation.');
      debugPrint('Load messages error: $e');
    }
  }

  /// Sends the composer's text as a follow-up message on the open enquiry.
  ///
  /// Requires a signed-in user, an open enquiry, a non-empty message, and a
  /// non-resolved enquiry (resolved threads are read-only). On success, clears
  /// the composer and reloads the thread.
  Future<void> _sendMessage() async {
    final user = _supabase.auth.currentUser;
    final enquiry = _selectedEnquiry;
    final message = _messageController.text.trim();

    if (user == null || enquiry == null) {
      _showMessage('Please log in and select an enquiry.');
      return;
    }

    if (message.isEmpty) {
      _showMessage('Please type a message first.');
      return;
    }

    // Resolved enquiries are closed for new messages.
    if ((enquiry['status'] ?? '').toString().toLowerCase() ==
        'resolved') {
      _showMessage(
        'This enquiry is resolved. Reopen it before sending a message.',
      );
      return;
    }

    setState(() {
      _sending = true;
    });

    try {
      // Insert the message with `student_id` set and `staff_id` null so the
      // bubble renders on the student's side of the thread.
      await _supabase.from('enquiry_messages').insert({
        'enquiry_ReferenceNo': enquiry['ReferenceNo'],
        'message': message,
        'student_id': user.id,
        'staff_id': null,
      });

      _messageController.clear();

      // Reload so the new message is included and the view scrolls down.
      await _loadMessages();

      if (!mounted) return;

      setState(() {
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _sending = false;
      });

      _showMessage('Could not send your message. Please try again.');
      debugPrint('Send message error: $e');
    }
  }

  /// Marks the currently open enquiry as resolved.
  ///
  /// Updates the row in Supabase, then mirrors the change locally in both
  /// [_selectedEnquiry] and the corresponding entry in [_enquiries] so the
  /// UI updates without a full reload.
  Future<void> _markResolved() async {
    final user = _supabase.auth.currentUser;
    final enquiry = _selectedEnquiry;

    if (user == null || enquiry == null) return;

    final currentStatus =
        (enquiry['status'] ?? '').toString().toLowerCase();

    if (currentStatus == 'resolved') {
      _showMessage('This enquiry is already resolved.');
      return;
    }

    setState(() {
      _updatingStatus = true;
    });

    try {
      // Scoped by `student_id` so a user can only resolve their own enquiry.
      await _supabase
          .from('enquiries')
          .update({'status': 'Resolved'})
          .eq('ReferenceNo', enquiry['ReferenceNo'])
          .eq('student_id', user.id);

      if (!mounted) return;

      setState(() {
        // Update the selected enquiry's status in place.
        _selectedEnquiry = {
          ..._selectedEnquiry!,
          'status': 'Resolved',
        };

        // Update the matching row in the enquiry list.
        _enquiries = _enquiries.map((item) {
          if (item['ReferenceNo'] == enquiry['ReferenceNo']) {
            return {...item, 'status': 'Resolved'};
          }

          return item;
        }).toList();

        _updatingStatus = false;
      });

      _showMessage('Enquiry marked as resolved.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _updatingStatus = false;
      });

      _showMessage('Could not update the enquiry status.');
      debugPrint('Resolve enquiry error: $e');
    }
  }

  /// Shows a snackbar with [message] (no-op if the widget is unmounted).
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Maps a status string to a display colour.
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'answered':
        return Colors.green;
      case 'resolved':
        return Colors.blueGrey;
      case 'pending':
        return Colors.orange;
      default:
        return AppTheme.buttonColor;
    }
  }

  /// Builds the small coloured status pill used in lists and the header.
  Widget _buildStatus(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: _statusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        // Fall back to "Pending" for empty strings.
        status.isEmpty ? 'Pending' : status,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Builds the enquiry list (list mode), handling loading / error / empty
  /// states and wrapping the populated list in a pull-to-refresh.
  Widget _buildEnquiryList() {
    if (_loadingEnquiries) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state (only shown when there's nothing cached to display).
    if (_error != null && _enquiries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadEnquiries,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    // Empty state.
    if (_enquiries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mark_email_unread_outlined, size: 48),
              SizedBox(height: 12),
              Text(
                'No enquiries yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your property enquiries and staff replies will appear here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Populated list with pull-to-refresh.
    return RefreshIndicator(
      onRefresh: _loadEnquiries,
      child: ListView.separated(
        // Always scrollable so pull-to-refresh works even when short.
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _enquiries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final enquiry = _enquiries[index];

          final subject =
              (enquiry['subject'] ?? 'Property enquiry').toString();

          final status =
              (enquiry['status'] ?? 'Pending').toString();

          final date = _formatDate(enquiry['created_at']);

          return Card(
            elevation: 1,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                backgroundColor: AppTheme.cardColor,
                child: const Icon(Icons.mail_outline),
              ),
              title: Text(
                subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatus(status),
                    // Date only rendered when parseable.
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(date),
                    ],
                    const SizedBox(height: 6),
                    // Preview of the enquiry body.
                    Text(
                      (enquiry['message'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              // Open this enquiry's thread.
              onTap: () => _openEnquiry(enquiry),
            ),
          );
        },
      ),
    );
  }

  /// Builds a single chat bubble for one message.
  ///
  /// Bubbles are right-aligned (purple) for the current student's messages
  /// (including the synthesised original enquiry) and left-aligned (green) for
  /// staff replies. A sender label is shown inside each bubble.
  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    String currentUserId,
  ) {
    final senderId = message['student_id']?.toString();
    final staffId = message['staff_id']?.toString();

    // The synthesised first message is the original enquiry body.
    final isOriginal = message['is_original_enquiry'] == true;

    // Any non-original message with a non-blank staff_id is a staff reply.
    final isStaff = !isOriginal &&
        staffId != null &&
        staffId.trim().isNotEmpty;

    final isStudent = isOriginal ||
        (!isStaff && senderId == currentUserId);

    final text = (message['message'] ?? '').toString();
    final date = _formatDate(message['created_at']);

    // Easy Rentals brand colours
    const purple = Color(0xFF6428D9);
    const lightGreen = Color(0xFFF1F7EC);

    final alignment = isStudent
        ? Alignment.centerRight
        : Alignment.centerLeft;

    // Purple for the student's own messages, light green for staff replies.
    final bubbleColor = isStudent ? purple : lightGreen;
    final messageTextColor =
        isStudent ? Colors.white : const Color(0xFF26351E);
    final timestampColor =
        isStudent ? const Color(0xFFE8DEFF) : const Color(0xFF64745A);

    final senderLabel = isOriginal
        ? 'Original enquiry'
        : isStaff
            ? 'Easy Rentals Staff'
            : isStudent
                ? 'You'
                : 'Sender unknown';

    return Align(
      alignment: alignment,
      child: Container(
        // Cap bubbles at 78% of the screen width for readability.
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sender label ("Original enquiry", "Easy Rentals Staff", ...).
            Text(
              senderLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: messageTextColor,
              ),
            ),
            const SizedBox(height: 5),
            // Message body.
            Text(
              text,
              style: TextStyle(
                color: messageTextColor,
              ),
            ),
            // Timestamp (only when parseable).
            if (date.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                date,
                style: TextStyle(
                  fontSize: 10,
                  color: timestampColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the conversation view (conversation mode): a header with a back
  /// button, subject, and status pill; a scrollable thread; a composer; and
  /// (unless resolved) a "Mark as Resolved" button.
  Widget _buildConversation() {
    final enquiry = _selectedEnquiry!;
    final user = _supabase.auth.currentUser;

    final subject =
        (enquiry['subject'] ?? 'Property enquiry').toString();

    final status =
        (enquiry['status'] ?? 'Pending').toString();

    final isResolved = status.toLowerCase() == 'resolved';

    return Column(
      children: [
        // Header row: back arrow + subject + status pill.
        Row(
          children: [
            IconButton(
              onPressed: () {
                // Return to list mode.
                setState(() {
                  _selectedEnquiry = null;
                  _messages = [];
                });
              },
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatus(status),
          ],
        ),
        const Divider(),

        // Message thread (or loading / empty states).
        Expanded(
          child: _loadingMessages
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No replies yet. You can send a follow-up below.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(
                          _messages[index],
                          user?.id ?? '',
                        );
                      },
                    ),
        ),

        // Composer — replaced by a status note when the enquiry is resolved.
        if (isResolved)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'This enquiry has been resolved.',
              textAlign: TextAlign.center,
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Auto-growing text field (1–4 lines).
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a follow-up message...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send button; shows a spinner while a send is in-flight.
                IconButton.filled(
                  onPressed: _sending ? null : _sendMessage,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),

        // Resolve action — only shown while the enquiry is still open.
        if (!isResolved)
          Padding(
            padding: const EdgeInsets.only(
              left: 8,
              right: 8,
              bottom: 8,
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _updatingStatus ? null : _markResolved,
                child: _updatingStatus
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Mark as Resolved'),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page heading — only shown in list mode.
            if (_selectedEnquiry == null) ...[
              const Text(
                'My Messages',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your property enquiries and conversations.',
              ),
              const SizedBox(height: 16),
            ],
            // Body switches between list and conversation based on selection.
            Expanded(
              child: _selectedEnquiry == null
                  ? _buildEnquiryList()
                  : _buildConversation(),
            ),
          ],
        ),
      ),
    );
  }
}