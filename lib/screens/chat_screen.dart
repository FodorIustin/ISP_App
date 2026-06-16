// Add to Firebase Console Storage Rules:
// rules_version = '2';
// service firebase.storage {
//   match /b/{bucket}/o {
//     match /chat_images/{allPaths=**} {
//       allow read, write: if request.auth != null;
//     }
//     match /users/{allPaths=**} {
//       allow read, write: if request.auth != null;
//     }
//   }
// }

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';
import '../screens/leaderboard_screen.dart' show getCountryFlag;
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.chatId});
  final String chatId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatService = ChatService();
  final _scrollController = ScrollController();
  final _controller = TextEditingController();

  bool _loading = true;
  bool _isSending = false;
  XFile? _selectedImage;

  String _chatType = 'global';
  String _chatName = '';
  String _subtitle = '';
  String? _otherUserPhotoUrl;
  String _currentUserId = '';
  int _lastMessageCount = 0;

  static const _senderColors = [
    Color(0xff3eb1c8),
    Color(0xff007398),
    Color(0xffdd7d1b),
    Color(0xff003e6d),
    Color(0xfff9b625),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _loadChatInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ─── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadChatInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _currentUserId = uid;

    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();

    if (!mounted) return;

    if (!chatDoc.exists) {
      setState(() => _loading = false);
      return;
    }

    final data = chatDoc.data()!;
    final type = data['type'] as String? ?? 'global';
    String name = '';
    String subtitle = '';
    String? otherUserPhotoUrl;

    if (type == 'direct') {
      final participantIds =
          List<String>.from(data['participantIds'] as List? ?? []);
      final otherUserId = participantIds.firstWhere(
        (id) => id != uid,
        orElse: () => '',
      );
      final participantNames = Map<String, dynamic>.from(
        data['participantNames'] as Map? ?? {},
      );
      name = participantNames[otherUserId] as String? ?? 'Unknown';
      subtitle = 'Direct message';

      if (otherUserId.isNotEmpty) {
        final otherDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .get();
        if (!mounted) return;
        otherUserPhotoUrl = otherDoc.data()?['photoUrl'] as String?;
        if (otherUserPhotoUrl != null && otherUserPhotoUrl.isEmpty) {
          otherUserPhotoUrl = null;
        }
      }
    } else if (type == 'country') {
      name = data['name'] as String? ?? 'Country Team';
      subtitle = 'Country team chat';
    } else {
      name = 'Everyone';
      final usersSnap =
          await FirebaseFirestore.instance.collection('users').get();
      if (!mounted) return;
      subtitle = 'All ${usersSnap.docs.length} attendees';
    }

    if (!mounted) return;
    setState(() {
      _chatType = type;
      _chatName = name;
      _subtitle = subtitle;
      _otherUserPhotoUrl = otherUserPhotoUrl;
      _loading = false;
    });
  }

  // ─── Actions ───────────────────────────────────────────────────────────────

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );
    if (image != null && mounted) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending) return;
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() => _isSending = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _chatService.uploadChatImage(
          widget.chatId,
          _selectedImage!,
        );
      }

      await _chatService.sendMessage(
        chatId: widget.chatId,
        text: text,
        imageUrl: imageUrl,
      );

      _controller.clear();
      setState(() {
        _selectedImage = null;
        _isSending = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (_) {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static Color _colorForSender(String senderId) =>
      _senderColors[senderId.hashCode.abs() % _senderColors.length];

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _dateSeparatorLabel(DateTime dt) {
    if (_isSameDay(dt, DateTime.now())) return 'Today';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xff003e6d),
                      ),
                    )
                  : _buildMessagesList(),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  // ─── AppBar ────────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    final titleContent = _chatType == 'direct' && _chatName.isNotEmpty
        ? Row(
            children: [
              _buildAppBarAvatar(),
              const SizedBox(width: 10),
              _buildTitleColumn(),
            ],
          )
        : _buildTitleColumn();

    return AppBar(
      backgroundColor: const Color(0xff003e6d),
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: titleContent,
    );
  }

  Widget _buildTitleColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _chatName,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        if (_subtitle.isNotEmpty)
          Text(
            _subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildAppBarAvatar() {
    if (_otherUserPhotoUrl != null) {
      return CircleAvatar(
        radius: 17,
        backgroundImage: NetworkImage(_otherUserPhotoUrl!),
      );
    }
    return Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(
        color: Color(0xff007398),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(_chatName),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  // ─── Messages list ─────────────────────────────────────────────────────────

  Widget _buildMessagesList() {
    return StreamBuilder<List<ChatMessage>>(
      stream: _chatService.getMessages(widget.chatId),
      builder: (_, snap) {
        final messages = snap.data ?? [];

        if (messages.length > _lastMessageCount) {
          _lastMessageCount = messages.length;
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToBottom(),
          );
        }

        if (messages.isEmpty &&
            snap.connectionState != ConnectionState.waiting) {
          return _buildEmptyState();
        }

        final widgets = <Widget>[];
        DateTime? lastDate;

        for (final msg in messages) {
          final msgDay = DateTime(
            msg.createdAt.year,
            msg.createdAt.month,
            msg.createdAt.day,
          );
          if (lastDate == null || !_isSameDay(lastDate, msgDay)) {
            widgets.add(_buildDateSeparator(msg.createdAt));
            lastDate = msgDay;
          }
          final isOwn = msg.senderId == _currentUserId;
          widgets.add(
            isOwn ? _buildOwnMessage(msg) : _buildOtherMessage(msg),
          );
        }

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          children: widgets,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Color(0xffe0ddd6),
          ),
          SizedBox(height: 12),
          Text(
            'No messages yet',
            style: TextStyle(fontSize: 14, color: Color(0xff888888)),
          ),
          SizedBox(height: 4),
          Text(
            'Be the first to say hello!',
            style: TextStyle(fontSize: 12, color: Color(0xffbbbbbb)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xfff0f0f0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _dateSeparatorLabel(dt),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xff888888),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnMessage(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xff003e6d),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            msg.imageUrl!,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (msg.text.isNotEmpty) const SizedBox(height: 6),
                      ],
                      if (msg.text.isNotEmpty)
                        Text(
                          msg.text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(msg.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xff888888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtherMessage(ChatMessage msg) {
    final color = _colorForSender(msg.senderId);
    final flag = getCountryFlag(msg.senderCountry);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              _initials(msg.senderName),
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${msg.senderName} · $flag',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff888888),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xfff8f7f4),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (msg.imageUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            msg.imageUrl!,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        if (msg.text.isNotEmpty) const SizedBox(height: 6),
                      ],
                      if (msg.text.isNotEmpty)
                        Text(
                          msg.text,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xff0f1923),
                            height: 1.4,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(msg.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xff888888),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Input area ────────────────────────────────────────────────────────────

  Widget _buildInputArea() {
    final canSend =
        _controller.text.trim().isNotEmpty || _selectedImage != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xffeeeeee), width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        8 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedImage != null) ...[
            _buildImagePreview(),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.photo_outlined),
                color: const Color(0xff888888),
                iconSize: 22,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: _pickImage,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: 4,
                  minLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xff0f1923),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Color(0xffbbbbbb),
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: (canSend && !_isSending) ? _sendMessage : null,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: canSend
                        ? const Color(0xff003e6d)
                        : const Color(0xffe0ddd6),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(9),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 18,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_selectedImage!.path),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImage = null),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
