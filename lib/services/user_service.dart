// Firestore rules required (update in Firebase Console):
//
// match /users/{uid} {
//   allow read: if request.auth != null;   // readable by all for leaderboard + online
//   allow write: if request.auth != null && request.auth.uid == uid;
// }
//
// Index required: Collection 'users', Field: lastSeen (Ascending)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Stream<AppUser?> getCurrentUser() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  Stream<List<Map<String, dynamic>>> getCountryLeaderboard() {
    return _db.collection('users').snapshots().map((snap) {
      final Map<String, int> countryPoints = {};
      final Map<String, int> countryMembers = {};

      for (final doc in snap.docs) {
        final data = doc.data();
        final country = data['country'] as String? ?? 'Unknown';
        final points = (data['points'] as num?)?.toInt() ?? 0;
        countryPoints[country] = (countryPoints[country] ?? 0) + points;
        countryMembers[country] = (countryMembers[country] ?? 0) + 1;
      }

      final leaderboard = countryPoints.entries
          .map((e) => {
                'country': e.key,
                'points': e.value,
                'members': countryMembers[e.key] ?? 0,
              })
          .toList();

      leaderboard.sort(
        (a, b) => (b['points'] as int).compareTo(a['points'] as int),
      );

      return leaderboard;
    });
  }

  Stream<List<AppUser>> getOnlineUsers() {
    return _db.collection('users').snapshots().map((snap) {
      final twoMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 2));
      return snap.docs
          .map((doc) => AppUser.fromFirestore(doc))
          .where((u) => u.lastSeen != null && u.lastSeen!.isAfter(twoMinutesAgo))
          .toList();
    });
  }

  Stream<List<AppUser>> getAllUsersWithStatus() {
    return _db
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromFirestore).toList());
  }

  Future<void> updateProfile({
    required String name,
    required String country,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'name': name,
      'country': country,
    });
  }
}
