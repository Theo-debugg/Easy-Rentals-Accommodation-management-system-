
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_rentals_mobile_app/Views/shared/app_theme.dart';

class MessagesTab extends StatefulWidget {
  const MessagesTab({super.key});

  @override
  State<MessagesTab> createState() => _MessagesTabState();
}

class _MessagesTabState extends State<MessagesTab> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _messageController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _enquiries = [];
  List<Map<String, dynamic>> _messages = [];

  Map<String, dynamic>? _selectedEnquiry;

  bool _loadingEnquiries = true;
  bool _loadingMessages = false;
  bool _sending = false;
  bool _updatingStatus = false;

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

  
Future<void> _loadMessages() async {
  final enquiry = _selectedEnquiry;

  if (enquiry == null) return;

  try {
    final referenceNo = enquiry['ReferenceNo'];

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
      await _supabase.from('enquiry_messages').insert({
        'enquiry_ReferenceNo': enquiry['ReferenceNo'],
        'message': message,
        'student_id': user.id,
        'staff_id': null,
      });

      _messageController.clear();

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
      await _supabase
          .from('enquiries')
          .update({'status': 'Resolved'})
          .eq('ReferenceNo', enquiry['ReferenceNo'])
          .eq('student_id', user.id);

      if (!mounted) return;

      setState(() {
        _selectedEnquiry = {
          ..._selectedEnquiry!,
          'status': 'Resolved',
        };

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

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
        status.isEmpty ? 'Pending' : status,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEnquiryList() {
    if (_loadingEnquiries) {
      return const Center(child: CircularProgressIndicator());
    }

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

    return RefreshIndicator(
      onRefresh: _loadEnquiries,
      child: ListView.separated(
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
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(date),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      (enquiry['message'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openEnquiry(enquiry),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    String currentUserId,
  ) {
    final senderId = message['student_id']?.toString();

final isOriginal =
    message['is_original_enquiry'] == true;

final isStudent = isOriginal || senderId == currentUserId;

    final text = (message['message'] ?? '').toString();
    final date = _formatDate(message['created_at']);

    return Align(
      alignment:
          isStudent ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isStudent ? AppTheme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
             isOriginal
    ? 'Original enquiry'
    : isStudent
        ? 'You'
        : 'Easy Rental Staff',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(text),
            if (date.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
        Row(
          children: [
            IconButton(
              onPressed: () {
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
