const functions = require('firebase-functions/v1');
const admin = require('firebase-admin');
admin.initializeApp();

exports.onUserProgressDeleted = functions.firestore
  .document('userProgress/{docId}')
  .onDelete(async (snap, context) => {
    const data = snap.data();
    const userId = data.userId;
    const lessonId = data.lessonId;
    const wasCompleted = data.completed === true;
    const pointsAwarded = data.pointsAwarded === true;

    const db = admin.firestore();
    const batch = db.batch();

    // 1. Delete all userAnswers for this user + lesson
    const answersSnapshot = await db
      .collection('userAnswers')
      .where('userId', '==', userId)
      .where('lessonId', '==', lessonId)
      .get();

    answersSnapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    // 2. Subtract points if they were awarded
    if (pointsAwarded || wasCompleted) {
      // Reading points
      const lessonDoc = await db
        .collection('lessons')
        .doc(lessonId)
        .get();
      const readingPoints =
        lessonDoc.data()?.pointsForReading ?? 10;

      // Answer points
      let answerPoints = 0;
      answersSnapshot.docs.forEach(doc => {
        answerPoints += doc.data().pointsEarned ?? 0;
      });

      const totalToSubtract = readingPoints + answerPoints;

      if (totalToSubtract > 0) {
        const userRef = db.collection('users').doc(userId);
        batch.update(userRef, {
          points: admin.firestore.FieldValue
            .increment(-totalToSubtract),
        });
      }
    }

    await batch.commit();
    console.log(
      `Cleaned up progress for user ${userId} lesson ${lessonId}`
    );
  });
