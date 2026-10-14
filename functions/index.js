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

// ------------------------------------------------------------------ translations
// requestTranslation: a signed-in user asks for a document in a language. Returns the
// cached translation, joins one that is running, or starts the translation job
// (isp-doc-translate, Cloud Run Job "isp-translate"). Logic: translation/*.js.
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { requestTranslation, RequestError } = require('./translation/request');

const TRANSLATION = {
  region: 'us-central1',          // same region as Firestore (nam5) and the job
  job: 'isp-translate',
  // identity of the function: may read/write Firestore and start the job, nothing else
  // (granted by scripts/deploy-translation.sh)
  serviceAccount: 'isp-functions@',
};

let runClient = null;
async function runJob(recordId) {
  const { JobsClient } = require('@google-cloud/run').v2;
  runClient = runClient || new JobsClient();
  const project = process.env.GCLOUD_PROJECT;
  // start the execution; its result is the record's status, not this call
  await runClient.runJob({
    name: `projects/${project}/locations/${TRANSLATION.region}/jobs/${TRANSLATION.job}`,
    overrides: { containerOverrides: [{ args: ['worker', recordId] }] },
  });
}

let languagesCache = { at: 0, list: [] };
async function offeredLanguages() {
  if (Date.now() - languagesCache.at < 5 * 60 * 1000) return languagesCache.list;
  const snap = await admin.firestore().doc('config/translation').get();
  const list = (snap.exists && snap.data().languages) || [];
  languagesCache = { at: Date.now(), list };
  return list;
}

exports.requestTranslation = onCall(
  { region: TRANSLATION.region, serviceAccount: TRANSLATION.serviceAccount, maxInstances: 10 },
  async (request) => {
    try {
      return await requestTranslation(request.auth ? request.auth.uid : null, request.data, {
        db: admin.firestore(),
        runJob,
        languages: offeredLanguages,
        now: () => Date.now() / 1000,
        timestamp: () => admin.firestore.FieldValue.serverTimestamp(),
        log: (...a) => console.log(...a),
      });
    } catch (e) {
      if (e instanceof RequestError) throw new HttpsError(e.code, e.message);
      console.error(e);
      throw new HttpsError('internal', 'translation request failed');
    }
  },
);

// ------------------------------------------------------------------ documents
// publishDocument: an uploader turns a file they put in uploads/{uid}/ into a document.
// deleteDocument: the uploader removes it with all its translations.
// Logic: translation/documents.js. Uploaders are listed in uploaders/{uid} (server only;
// scripts/add-uploader.sh).
const { publishDocument, deleteDocument } = require('./translation/documents');

function documentDeps() {
  const fs = admin.firestore();
  const bucket = admin.storage().bucket();
  return {
    db: {
      doc: (path) => fs.doc(path),
      translationsOf: async (documentId) =>
        (await fs.collection('translations').where('documentId', '==', documentId).get())
          .docs.map((d) => d.ref),
    },
    storage: {
      size: async (path) => {
        try {
          const [meta] = await bucket.file(path).getMetadata();
          return Number(meta.size);
        } catch (e) {
          if (e && e.code === 404) return null;
          throw e;
        }
      },
      read: async (path) => (await bucket.file(path).download())[0],
      copy: (from, to) => bucket.file(from).copy(bucket.file(to)),
      delete: (path) => bucket.file(path).delete({ ignoreNotFound: true }),
      deletePrefix: (prefix) => bucket.deleteFiles({ prefix }),
    },
    newId: () => fs.collection('documents').doc().id,
    timestamp: () => admin.firestore.FieldValue.serverTimestamp(),
    log: (...a) => console.log(...a),
  };
}

function callable(fn, extra = {}) {
  return onCall(
    { region: TRANSLATION.region, serviceAccount: TRANSLATION.serviceAccount, maxInstances: 5,
      ...extra },
    async (request) => {
      try {
        return await fn(request.auth ? request.auth.uid : null, request.data, documentDeps());
      } catch (e) {
        if (e instanceof RequestError) throw new HttpsError(e.code, e.message);
        console.error(e);
        throw new HttpsError('internal', 'request failed');
      }
    },
  );
}

// reads the whole upload (at most 50 MB) to check what it really is
exports.publishDocument = callable(publishDocument, { memory: '512MiB', timeoutSeconds: 120 });
exports.deleteDocument = callable(deleteDocument, { timeoutSeconds: 120 });
