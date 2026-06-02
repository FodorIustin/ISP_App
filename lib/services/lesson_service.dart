// Firestore security rules required for this service:
//
// match /userProgress/{doc} {
//   allow read, write: if request.auth != null;
// }
// match /lessons/{doc} {
//   allow read: if request.auth != null;
//   allow write: if false;
// }
// match /userAnswers/{doc} {
//   allow read: if request.auth != null
//     && resource.data.userId == request.auth.uid;
//   allow write: if request.auth != null;
// }

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

  Future<Lesson?> getLessonById(String lessonId) async {
    final doc = await _db.collection('lessons').doc(lessonId).get();
    if (!doc.exists) return null;
    return Lesson.fromFirestore(doc);
  }

  Future<void> markLessonProgress(
    String lessonId,
    double progress,
    int currentSection,
  ) async {
    final uid = _uid;
    if (uid == null) return;

    final progressRef = _db.collection('userProgress').doc(_docId(lessonId));
    final existing = await progressRef.get();

    if (!existing.exists) {
      final staleAnswers = await _db
          .collection('userAnswers')
          .where('userId', isEqualTo: uid)
          .where('lessonId', isEqualTo: lessonId)
          .get();
      if (staleAnswers.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final doc in staleAnswers.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    }

    await progressRef.set({
      'userId': uid,
      'lessonId': lessonId,
      'progress': progress,
      'currentSection': currentSection,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getLessonProgress(String lessonId) async {
    if (_uid == null) return {'progress': 0.0, 'currentSection': 0};
    final doc =
        await _db.collection('userProgress').doc(_docId(lessonId)).get();
    if (!doc.exists) return {'progress': 0.0, 'currentSection': 0};
    final data = doc.data()!;
    return {
      'progress': (data['progress'] as num?)?.toDouble() ?? 0.0,
      'currentSection': (data['currentSection'] as num?)?.toInt() ?? 0,
    };
  }

  Future<void> markLessonCompleted(String lessonId) async {
    final uid = _uid;
    if (uid == null) return;

    final progressRef = _db.collection('userProgress').doc(_docId(lessonId));
    final existing = await progressRef.get();
    final alreadyAwarded = existing.data()?['pointsAwarded'] == true;

    final batch = _db.batch();

    batch.set(progressRef, {
      'userId': uid,
      'lessonId': lessonId,
      'completed': true,
      'completedAt': FieldValue.serverTimestamp(),
      'pointsAwarded': true,
    }, SetOptions(merge: true));

    if (!alreadyAwarded) {
      final lessonDoc = await _db.collection('lessons').doc(lessonId).get();
      final points =
          (lessonDoc.data()?['pointsForReading'] as num?)?.toInt() ?? 10;
      batch.update(_db.collection('users').doc(uid), {
        'points': FieldValue.increment(points),
      });
    }

    await batch.commit();
  }

  Future<bool> hasAnsweredQuestions(String lessonId) async {
    final uid = _uid;
    if (uid == null) return false;

    final progressDoc = await _db
        .collection('userProgress')
        .doc(_docId(lessonId))
        .get();
    if (!progressDoc.exists) return false;

    final answersSnapshot = await _db
        .collection('userAnswers')
        .where('userId', isEqualTo: uid)
        .where('lessonId', isEqualTo: lessonId)
        .get();
    return answersSnapshot.docs.isNotEmpty;
  }

  Future<bool> isLessonCompleted(String lessonId) async {
    final uid = _uid;
    if (uid == null) return false;

    final doc =
        await _db.collection('userProgress').doc(_docId(lessonId)).get();
    if (!doc.exists) return false;
    return doc.data()?['completed'] == true;
  }

  Future<void> saveQuestionAnswer({
    required String lessonId,
    required int questionIndex,
    String? answerText, // only set for open text questions
    required bool isCorrect,
    required int points,
  }) async {
    final uid = _uid;
    if (uid == null) return;

    final progressDoc = await _db
        .collection('userProgress')
        .doc(_docId(lessonId))
        .get();
    if (!progressDoc.exists) return;

    final docId = '${uid}_${lessonId}_$questionIndex';
    final docRef = _db.collection('userAnswers').doc(docId);

    final existing = await docRef.get();
    final firstAnswer = !existing.exists;

    await docRef.set({
      'userId': uid,
      'lessonId': lessonId,
      'questionIndex': questionIndex,
      // ignore: use_null_aware_elements
      if (answerText != null) 'answerText': answerText,
      'isCorrect': isCorrect,
      'pointsEarned': points,
      'answeredAt': FieldValue.serverTimestamp(),
    });

    if (firstAnswer && isCorrect && points > 0) {
      await _db
          .collection('users')
          .doc(uid)
          .update({'points': FieldValue.increment(points)});
    }
  }

  // Requires a composite index on userAnswers: (userId ASC, lessonId ASC).
  // Firebase will print a console link to create it on first run.
  Future<void> resetLessonProgress(String lessonId) async {
    final uid = _uid;
    if (uid == null) return;

    final progressRef =
        _db.collection('userProgress').doc(_docId(lessonId));

    // Fetch before the batch so we can calculate points to subtract.
    final answersSnap = await _db
        .collection('userAnswers')
        .where('userId', isEqualTo: uid)
        .where('lessonId', isEqualTo: lessonId)
        .get();

    final progressDoc = await progressRef.get();

    int pointsToSubtract = 0;
    for (final doc in answersSnap.docs) {
      pointsToSubtract +=
          (doc.data()['pointsEarned'] as num?)?.toInt() ?? 0;
    }
    if (progressDoc.exists &&
        progressDoc.data()?['completed'] == true) {
      pointsToSubtract += 10; // pointsForReading
    }

    final batch = _db.batch();

    batch.delete(progressRef);
    for (final doc in answersSnap.docs) {
      batch.delete(doc.reference);
    }
    if (pointsToSubtract > 0) {
      batch.update(_db.collection('users').doc(uid),
          {'points': FieldValue.increment(-pointsToSubtract)});
    }

    await batch.commit();
  }

  // Fetches answer points by constructing doc IDs directly — no composite index needed.
  Future<Map<String, dynamic>> getLessonResults(String lessonId) async {
    final uid = _uid;
    if (uid == null) return {'answerPoints': 0, 'correctCount': 0};

    final futures = List.generate(
      10,
      (i) => _db.collection('userAnswers').doc('${uid}_${lessonId}_$i').get(),
    );
    final docs = await Future.wait(futures);

    int answerPoints = 0;
    int correctCount = 0;
    for (final doc in docs) {
      if (!doc.exists) continue;
      final data = doc.data()!;
      answerPoints += (data['pointsEarned'] as num?)?.toInt() ?? 0;
      if (data['isCorrect'] == true) correctCount++;
    }

    return {'answerPoints': answerPoints, 'correctCount': correctCount};
  }
}
