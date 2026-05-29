import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PresenceService {
  final _db = FirebaseFirestore.instance;

  Future<void> setOnline() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setOffline() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({
      'isOnline': false,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  // Requires an index on users.lastSeen (Ascending) in Firebase Console.
  Stream<List<Map<String, dynamic>>> getOnlineUsers() {
    final twoMinutesAgo = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(minutes: 2)),
    );
    return _db
        .collection('users')
        .where('lastSeen', isGreaterThan: twoMinutesAgo)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList());
  }

  Stream<List<Map<String, dynamic>>> getAllUsersWithStatus() {
    return _db.collection('users').snapshots().map((snap) {
      final twoMinutesAgo =
          DateTime.now().subtract(const Duration(minutes: 2));
      return snap.docs.map((doc) {
        final data = doc.data();
        final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
        final isOnline =
            lastSeen != null && lastSeen.isAfter(twoMinutesAgo);
        return {'id': doc.id, ...data, 'isOnline': isOnline};
      }).toList();
    });
  }
}
