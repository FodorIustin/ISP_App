import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderCountry;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final String chatId;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderCountry,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    required this.chatId,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderCountry: data['senderCountry'] as String? ?? '',
      text: data['text'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      chatId: data['chatId'] as String? ?? '',
    );
  }
}

class ChatConversation {
  final String id;
  final String type;
  final String name;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final List<String> participantIds;
  final String? country;

  const ChatConversation({
    required this.id,
    required this.type,
    required this.name,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.participantIds = const [],
    this.country,
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      type: data['type'] as String? ?? 'direct',
      name: data['name'] as String? ?? '',
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      unreadCount: 0,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      country: data['country'] as String?,
    );
  }
}
