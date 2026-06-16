// Add to Firebase Console Firestore Rules:
// match /chats/{chatId} {
//   allow read, write: if request.auth != null;
// }
// match /chats/{chatId}/messages/{messageId} {
//   allow read, write: if request.auth != null;
// }
//
// Add to Firebase Console Storage Rules:
// match /chat_images/{allPaths=**} {
//   allow read, write: if request.auth != null;
// }
//
// Composite index needed (chats collection):
//   participantIds (Arrays) + type (Ascending) + lastMessageAt (Descending)
//
// If Firestore complains about index for direct chats query,
// the query uses: participantIds array-contains + type ==
// Create composite index in Firebase Console if needed

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../models/chat_message.dart';

class ChatService {
  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  Future<String> getOrCreateDirectChat(
    String otherUserId,
    String otherUserName,
    String otherUserCountry,
  ) async {
    final uid = _uid;
    if (uid == null) throw Exception('Not logged in');

    final ids = [uid, otherUserId]..sort();
    final chatId = '${ids[0]}_${ids[1]}';

    final chatRef = _db.collection('chats').doc(chatId);
    final existing = await chatRef.get();

    if (!existing.exists) {
      final currentUserDoc = await _db.collection('users').doc(uid).get();
      final currentUserName =
          currentUserDoc.data()?['name'] as String? ?? 'Unknown';
      final currentUserCountry =
          currentUserDoc.data()?['country'] as String? ?? '';

      await chatRef.set({
        'type': 'direct',
        'participantIds': [uid, otherUserId],
        'participantNames': {
          uid: currentUserName,
          otherUserId: otherUserName,
        },
        'participantCountries': {
          uid: currentUserCountry,
          otherUserId: otherUserCountry,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': null,
        'unreadCounts': {uid: 0, otherUserId: 0},
      });
    }
    return chatId;
  }

  Future<String> getGlobalChat() async {
    final chatRef = _db.collection('chats').doc('global');
    final existing = await chatRef.get();
    if (!existing.exists) {
      await chatRef.set({
        'type': 'global',
        'name': 'Everyone',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': null,
      });
    }
    return 'global';
  }

  Future<String> getCountryChat(String country) async {
    final chatId =
        'country_${country.toLowerCase().replaceAll(' ', '_')}';
    final chatRef = _db.collection('chats').doc(chatId);
    final existing = await chatRef.get();
    if (!existing.exists) {
      await chatRef.set({
        'type': 'country',
        'country': country,
        'name': '$country Team',
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': null,
      });
    }
    return chatId;
  }

  Stream<List<Map<String, dynamic>>> getUserConversations() {
    final uid = _uid;
    if (uid == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .asyncMap((userDoc) async {
      final country = userDoc.data()?['country'] as String? ?? '';
      final conversations = <Map<String, dynamic>>[];

      // 1. Global chat — auto-create if missing
      final globalRef =
          FirebaseFirestore.instance.collection('chats').doc('global');
      final globalDoc = await globalRef.get();
      if (!globalDoc.exists) {
        await globalRef.set({
          'type': 'global',
          'name': 'Everyone',
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': null,
          'lastMessageAt': null,
        });
      }
      final globalData = globalDoc.data() ?? {};
      conversations.add({
        'id': 'global',
        'type': 'global',
        'name': 'Everyone',
        'subtitle':
            globalData['lastMessage'] ?? 'Chat with all attendees',
        'lastMessageAt': globalData['lastMessageAt'],
        'icon': 'global',
      });

      // 2. Country chat — auto-create if missing
      if (country.isNotEmpty) {
        final countryId =
            'country_${country.toLowerCase().replaceAll(' ', '_')}';
        final countryRef = FirebaseFirestore.instance
            .collection('chats')
            .doc(countryId);
        final countryDoc = await countryRef.get();
        if (!countryDoc.exists) {
          await countryRef.set({
            'type': 'country',
            'country': country,
            'name': '$country Team',
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessage': null,
            'lastMessageAt': null,
          });
        }
        final countryData = countryDoc.data() ?? {};
        conversations.add({
          'id': countryId,
          'type': 'country',
          'name': '$country Team',
          'subtitle': countryData['lastMessage'] ??
              'Chat with your country teammates',
          'lastMessageAt': countryData['lastMessageAt'],
          'icon': 'country',
          'country': country,
        });
      }

      // 3. Direct chats — no orderBy to avoid composite index requirement
      final directConvos = <Map<String, dynamic>>[];
      try {
        final directChats = await FirebaseFirestore.instance
            .collection('chats')
            .where('participantIds', arrayContains: uid)
            .where('type', isEqualTo: 'direct')
            .get();

        for (final doc in directChats.docs) {
          final data = doc.data();
          final participantIds =
              List<String>.from(data['participantIds'] as List? ?? []);
          final otherUserId = participantIds.firstWhere(
            (id) => id != uid,
            orElse: () => '',
          );
          if (otherUserId.isEmpty) continue;

          final participantNames = Map<String, dynamic>.from(
            data['participantNames'] as Map? ?? {},
          );
          final otherName =
              participantNames[otherUserId]?.toString() ?? 'Unknown';
          final participantCountries = Map<String, dynamic>.from(
            data['participantCountries'] as Map? ?? {},
          );
          final otherCountry =
              participantCountries[otherUserId]?.toString() ?? '';

          directConvos.add({
            'id': doc.id,
            'type': 'direct',
            'name': otherName,
            'subtitle': data['lastMessage'] ?? otherCountry,
            'otherUserId': otherUserId,
            'lastMessage': data['lastMessage'],
            'lastMessageAt': data['lastMessageAt'],
            'icon': 'direct',
            'country': otherCountry,
          });
        }

        // Sort by most recent message, nulls last
        directConvos.sort((a, b) {
          final aTime = a['lastMessageAt'] as Timestamp?;
          final bTime = b['lastMessageAt'] as Timestamp?;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });
      } catch (_) {
        // Direct chats query failed — show channel chats only
      }

      conversations.addAll(directConvos);
      return conversations;
    });
  }

  Future<void> sendMessage({
    required String chatId,
    required String text,
    String? imageUrl,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final userDoc = await _db.collection('users').doc(uid).get();
    final senderName = userDoc.data()?['name'] as String? ?? 'Unknown';
    final senderCountry = userDoc.data()?['country'] as String? ?? '';

    final batch = _db.batch();

    final messageRef = _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': uid,
      'senderName': senderName,
      'senderCountry': senderCountry,
      'text': text,
      // ignore: use_null_aware_elements
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'chatId': chatId,
    });

    batch.update(_db.collection('chats').doc(chatId), {
      'lastMessage': imageUrl != null ? '📷 Photo' : text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<String?> uploadChatImage(String chatId, XFile imageFile) async {
    final uid = _uid;
    if (uid == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('chat_images')
        .child(chatId)
        .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

    final bytes = await imageFile.readAsBytes();
    await ref.putData(bytes);
    return ref.getDownloadURL();
  }

  Stream<List<ChatMessage>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map(ChatMessage.fromFirestore).toList());
  }
}
