import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/lesson.dart';

class LessonService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  String _docId(String lessonId) => '${_uid}_$lessonId';

  Stream<List<Lesson>> getLessons() {
    return _db
        .collection('lessons')
        .where('isVisible', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(Lesson.fromFirestore).toList());
  }

  Future<Lesson?> getLesson(String lessonId) async {
    final doc = await _db.collection('lessons').doc(lessonId).get();
    if (!doc.exists) return null;
    return Lesson.fromFirestore(doc);
  }

  Future<void> markLessonProgress(String lessonId, double progress) async {
    final uid = _uid;
    if (uid == null) return;
    await _db.collection('userProgress').doc(_docId(lessonId)).set({
      'userId': uid,
      'lessonId': lessonId,
      'progress': progress,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<double> getLessonProgress(String lessonId) async {
    if (_uid == null) return 0.0;
    final doc =
        await _db.collection('userProgress').doc(_docId(lessonId)).get();
    if (!doc.exists) return 0.0;
    return (doc.data()?['progress'] as num?)?.toDouble() ?? 0.0;
  }

  Future<void> markLessonCompleted(String lessonId) async {
    final uid = _uid;
    if (uid == null) return;
    if (await isLessonCompleted(lessonId)) return;

    final lessonDoc = await _db.collection('lessons').doc(lessonId).get();
    final points =
        (lessonDoc.data()?['pointsForReading'] as num?)?.toInt() ?? 0;

    await _db.collection('userProgress').doc(_docId(lessonId)).set({
      'userId': uid,
      'lessonId': lessonId,
      'progress': 1.0,
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db
        .collection('users')
        .doc(uid)
        .update({'points': FieldValue.increment(points)});
  }

  Future<bool> isLessonCompleted(String lessonId) async {
    if (_uid == null) return false;
    final doc =
        await _db.collection('userProgress').doc(_docId(lessonId)).get();
    return doc.data()?['completed'] == true;
  }
}
