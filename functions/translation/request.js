// requestTranslation: the one call the app makes to get a document in a language.
// Firebase and Cloud Run are passed in (deps), so the tests run it on fakes.

'use strict';

const L = require('./logic');

class RequestError extends Error {
  constructor(code, message) {
    super(message);
    this.code = code;
  }
}

/**
 * uid: the signed-in user (null = not signed in); data: {documentId, lang}.
 * deps: {
 *   db             Firestore (admin): doc(path).get(), runTransaction(fn)
 *   runJob(rid)    starts the translation job for a record
 *   languages()    [{code, name}] offered (config/translation)
 *   now()          seconds since 1970
 *   timestamp()    a server timestamp value for the record
 *   log(...)       logging
 * }
 * Returns {recordId, status, action}; throws RequestError(code, message).
 */
async function requestTranslation(uid, data, deps) {
  if (!uid) throw new RequestError('unauthenticated', 'sign in to request a translation');
  const { documentId, lang } = data || {};
  const bad = L.checkRequest({ documentId, lang, languages: await deps.languages() });
  if (bad) throw new RequestError(bad.code, bad.message);

  const docSnap = await deps.db.doc(`documents/${documentId}`).get();
  const doc = docSnap.exists ? docSnap.data() : null;
  const badDoc = L.checkDocument({ documentId, lang, doc });
  if (badDoc) throw new RequestError(badDoc.code, badDoc.message);

  const rid = L.recordId(documentId, lang);
  const ref = deps.db.doc(`translations/${rid}`);
  const now = deps.now();

  const result = await deps.db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const rec = snap.exists ? snap.data() : null;
    const action = L.decide(rec, now);
    if (action === 'create') {
      tx.set(ref, { ...L.newRecord({ documentId, lang, doc, uid, now }),
        requestedAt: deps.timestamp() });
      return { action, status: 'queued' };
    }
    const update = {};
    const requesters = rec.requesters || [];
    if (!requesters.includes(uid)) update.requesters = [...requesters, uid];
    if (action === 'restart') {
      update.status = 'queued';
      update.jobRequestedAt = now;
      update.leaseUntil = null;
    }
    if (Object.keys(update).length) tx.update(ref, update);
    return { action, status: update.status || rec.status };
  });

  if (result.action === 'create' || result.action === 'restart') {
    try {
      await deps.runJob(rid);
      deps.log(`translation ${rid}: job started (${result.action}) for ${uid}`);
    } catch (e) {
      // the next request starts it again at once instead of waiting for the grace period
      await ref.update({ jobRequestedAt: 0 });
      deps.log(`translation ${rid}: job could not be started: ${e && e.message}`);
      throw new RequestError('unavailable', 'the translation could not be started, try again');
    }
  } else {
    deps.log(`translation ${rid}: ${result.action} (${result.status}) for ${uid}`);
  }
  return { recordId: rid, status: result.status, action: result.action };
}

module.exports = { requestTranslation, RequestError };
