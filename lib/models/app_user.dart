import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String name;
  final String country;
  final String photoUrl;
  final int points;
  final bool isOnline;
  final DateTime? lastSeen;

  const AppUser({
    required this.uid,
    required this.name,
    required this.country,
    required this.photoUrl,
    required this.points,
    required this.isOnline,
    required this.lastSeen,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      country: data['country'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      points: (data['points'] as num?)?.toInt() ?? 0,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  bool get isCurrentlyOnline {
    if (lastSeen == null) return false;
    return lastSeen!.isAfter(
      DateTime.now().subtract(const Duration(minutes: 2)),
    );
  }
}
