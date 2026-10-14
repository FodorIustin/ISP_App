// Uploading and deleting documents. Firebase is passed in (deps) so the tests run on fakes.
//
// Upload, as the app does it:
//   1. the app puts the file in uploads/{uid}/{name}.{pdf|docx} (storage.rules: only the
//      owner, PDF/Word content types, at most MAX_BYTES)
//   2. it calls publishDocument({uploadPath, title, fileName})
//   3. here: the user must be an uploader (uploaders/{uid}, written only by the server);
//      the file must really be a PDF or a Word file (its first bytes, not its name);
//      it is moved to documents/{id}/source.{ext} and documents/{id} is created
// During testing a document is published at once; with approval it will start
// "in_review" (one value: SETTINGS.initialStatus).

'use strict';

const { RequestError } = require('./request');

const SETTINGS = {
  maxBytes: 50 * 1024 * 1024,   // same limit as storage.rules
  titleMax: 150,
  initialStatus: 'published',   // testing; becomes 'in_review' when approval exists
  sourceLang: 'en',             // the translator translates from English (for now)
};

const UPLOAD_RE = /^uploads\/([A-Za-z0-9]{1,128})\/[A-Za-z0-9_-]{1,100}\.(pdf|docx)$/;

/** 'pdf' | 'docx' | null from the first bytes of a file (not from its name). */
function sniff(bytes) {
  if (!bytes || bytes.length < 8) return null;
  if (bytes.subarray(0, 5).toString('latin1') === '%PDF-') return 'pdf';
  const zip = bytes[0] === 0x50 && bytes[1] === 0x4b && bytes[2] === 0x03 && bytes[3] === 0x04;
  // a Word file is a zip whose entries include word/document.xml (entry names are stored
  // uncompressed in the zip, so the name is visible in the raw bytes)
  if (zip && bytes.includes(Buffer.from('word/document.xml'))) return 'docx';
  return null;
}

function cleanTitle(title, fileName) {
  let t = typeof title === 'string' ? title.trim() : '';
  if (!t && typeof fileName === 'string') t = fileName.replace(/\.[^.]+$/, '').trim();
  t = t.replace(/\s+/g, ' ').slice(0, SETTINGS.titleMax);
  return t;
}

async function requireUploader(uid, db) {
  if (!uid) throw new RequestError('unauthenticated', 'sign in to upload');
  const snap = await db.doc(`uploaders/${uid}`).get();
  if (!snap.exists) throw new RequestError('permission-denied', 'your account may not upload documents');
}

/**
 * deps: {db, storage: {size(path), read(path), copy(from, to), delete(path),
 *        deletePrefix(prefix)}, newId(), timestamp(), log()}
 */
async function publishDocument(uid, data, deps) {
  await requireUploader(uid, deps.db);
  const { uploadPath, title, fileName } = data || {};
  const m = typeof uploadPath === 'string' ? UPLOAD_RE.exec(uploadPath) : null;
  if (!m || m[1] !== uid) throw new RequestError('invalid-argument', 'unexpected upload path');

  const size = await deps.storage.size(uploadPath);
  if (size === null) throw new RequestError('not-found', 'the uploaded file was not found');
  if (size === 0 || size > SETTINGS.maxBytes) {
    await deps.storage.delete(uploadPath);
    throw new RequestError('invalid-argument', 'the file is empty or larger than 50 MB');
  }
  const kind = sniff(await deps.storage.read(uploadPath));
  if (!kind) {
    await deps.storage.delete(uploadPath);
    throw new RequestError('invalid-argument', 'only PDF and Word (.docx) files can be uploaded');
  }
  const t = cleanTitle(title, fileName);
  if (!t) throw new RequestError('invalid-argument', 'the document needs a title');

  const id = deps.newId();
  const source = `documents/${id}/source.${kind}`;
  await deps.storage.copy(uploadPath, source);
  await deps.db.doc(`documents/${id}`).set({
    title: t,
    fileName: typeof fileName === 'string' ? fileName.slice(0, 200) : `${t}.${kind}`,
    source,
    sourceLang: SETTINGS.sourceLang,
    kind,
    status: SETTINGS.initialStatus,
    test: false,
    uploadedBy: uid,
    sizeBytes: size,
    createdAt: deps.timestamp(),
  });
  await deps.storage.delete(uploadPath);
  deps.log(`document ${id} published by ${uid}: ${t} (${kind}, ${size} bytes)`);
  return { documentId: id };
}

/** The uploader removes their document with its original and every translation. */
async function deleteDocument(uid, data, deps) {
  await requireUploader(uid, deps.db);
  const { documentId } = data || {};
  if (typeof documentId !== 'string' || !/^[A-Za-z0-9_-]{1,120}$/.test(documentId)) {
    throw new RequestError('invalid-argument', 'documentId is missing or malformed');
  }
  const ref = deps.db.doc(`documents/${documentId}`);
  const snap = await ref.get();
  if (!snap.exists) throw new RequestError('not-found', 'document not found');
  if (snap.data().uploadedBy !== uid) {
    throw new RequestError('permission-denied', 'only the person who uploaded it can delete it');
  }
  const records = await deps.db.translationsOf(documentId);
  for (const r of records) await r.delete();
  await deps.storage.deletePrefix(`translations/${documentId}/`);
  await deps.storage.deletePrefix(`documents/${documentId}/`);
  await ref.delete();
  deps.log(`document ${documentId} deleted by ${uid} (${records.length} translations)`);
  return { deleted: documentId, translations: records.length };
}

module.exports = { SETTINGS, sniff, cleanTitle, publishDocument, deleteDocument };
