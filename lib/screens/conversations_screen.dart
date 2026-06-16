import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/chat_service.dart';

String getCountryFlag(String country) {
  const flags = {
    'Albania': '🇦🇱',
    'Armenia': '🇦🇲',
    'Austria': '🇦🇹',
    'Belgium': '🇧🇪',
    'Bulgaria': '🇧🇬',
    'Czech Republic': '🇨🇿',
    'Greece': '🇬🇷',
    'Hungary': '🇭🇺',
    'Moldova': '🇲🇩',
    'Netherlands': '🇳🇱',
    'North Macedonia': '🇲🇰',
    'Poland': '🇵🇱',
    'Portugal': '🇵🇹',
    'Romania': '🇷🇴',
    'Spain': '🇪🇸',
    'Ukraine': '🇺🇦',
    'Russia': '🇷🇺',
  };
  return flags[country] ?? '🌍';
}

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff003e6d),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ChatService().getUserConversations(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xff003e6d),
              ),
            );
          }

          final conversations = snap.data ?? [];
          final channelConvos =
              conversations.where((c) => c['type'] != 'direct').toList();
          final directConvos =
              conversations.where((c) => c['type'] == 'direct').toList();

          return ListView(
            children: [
              for (final conv in channelConvos)
                _ConversationTile(conversation: conv, index: 0),
              if (directConvos.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Direct messages',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff888888),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                for (var i = 0; i < directConvos.length; i++)
                  _ConversationTile(
                    conversation: directConvos[i],
                    index: i,
                  ),
              ] else
                _buildEmptyHint(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyHint() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xfff8f7f4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: Color(0xff888888),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Start a conversation by visiting someone's profile",
              style: TextStyle(fontSize: 13, color: Color(0xff888888)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Conversation Tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.index,
  });

  final Map<String, dynamic> conversation;
  final int index;

  static const _directColors = [
    Color(0xff3eb1c8),
    Color(0xff007398),
    Color(0xffdd7d1b),
    Color(0xff003e6d),
  ];

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is! Timestamp) return '';
    final dt = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    if (msgDay == today) {
      return '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Widget _buildAvatar() {
    final type = conversation['type'] as String;
    if (type == 'global') {
      return Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: Color(0xff003e6d),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.language, color: Colors.white, size: 22),
      );
    }
    if (type == 'country') {
      final country = conversation['country'] as String? ?? '';
      final flag = getCountryFlag(country);
      return Container(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(
          color: Color(0xff007398),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(flag, style: const TextStyle(fontSize: 22)),
      );
    }
    // direct
    final name = conversation['name'] as String? ?? '';
    final color = _directColors[index % _directColors.length];
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = conversation['name'] as String? ?? '';
    final subtitle = conversation['subtitle'] as String? ?? '';
    final timeStr = _formatTime(conversation['lastMessageAt']);

    return GestureDetector(
      onTap: () => context.push('/chat/${conversation['id']}'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xffeeeeee), width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff0f1923),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff888888),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xff888888),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
