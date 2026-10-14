// What happens when a user asks for a document in a language. Pure logic, no Firebase,
// so it is tested on its own (test/translation.test.js).
//
// One record per (document, language): translations/{documentId}__{lang}. It is the
// cache: a finished translation is served again at no cost, a running one is shared by
// everyone who asks, and the record lists them all in `requesters`.
//
// The record's life (statuses written by the translation job, isp-doc-translate/worker.py):
//   queued -> running -> ready | needs_review | refused | failed

'use strict';

const SETTINGS = {
  // A job that was asked to start but has not taken the record yet. Cloud Run needs ~3
  // min to start an execution (measured 2026-10-14); after this the start counts as lost
  // and the next request starts it again.
  startGraceSeconds: 15 * 60,
};

const FINISHED = new Set(['ready', 'needs_review', 'refused']);
const ID_RE = /^[A-Za-z0-9_-]{1,120}$/;

function recordId(documentId, lang) {
  return `${documentId}__${lang}`;
}

/**
 * Checks the request itself. Returns null when valid, else {code, message} (HttpsError
 * codes). languages: [{code, name}] from config/translation.
 */
function checkRequest({ documentId, lang, languages }) {
  if (typeof documentId !== 'string' || !ID_RE.test(documentId)) {
    return { code: 'invalid-argument', message: 'documentId is missing or malformed' };
  }
  if (typeof lang !== 'string' || !languages.some((l) => l.code === lang)) {
    return { code: 'invalid-argument', message: `language not offered: ${lang}` };
  }
  return null;
}

/** Checks the document (documents/{id} or null) the request is for. */
function checkDocument({ documentId, lang, doc }) {
  if (!doc) {
    return { code: 'not-found', message: 'document not found' };
  }
  if (doc.status !== 'published') {
    return { code: 'failed-precondition', message: 'document is not published' };
  }
  if (typeof doc.source !== 'string' || !doc.source.startsWith(`documents/${documentId}/`)) {
    return { code: 'failed-precondition', message: 'document has no source file' };
  }
  if (doc.sourceLang && doc.sourceLang === lang) {
    return { code: 'invalid-argument', message: 'the document is already in this language' };
  }
  return null;
}

/**
 * What to do with an existing record (or none). now: seconds since 1970.
 * Returns one of:
 *   create   no record: create it queued and start the job
 *   served   finished (ready / needs_review / refused): nothing to run
 *   join     queued or running and alive: the requester shares that job
 *   restart  queued but the start was lost, or running but its worker died: the record
 *            goes back to queued and the job is started again (the job counts its
 *            attempts and gives up after its own limit, so this cannot loop)
 *   failed   the job gave up; only "regenerate" (later, admin) runs it again
 */
function decide(record, now, settings = SETTINGS) {
  if (!record) return 'create';
  const status = record.status;
  if (FINISHED.has(status)) return 'served';
  if (status === 'failed') return 'failed';
  if (status === 'running') {
    return (record.leaseUntil || 0) > now ? 'join' : 'restart';
  }
  // queued (or an unknown status: treated as queued)
  const asked = record.jobRequestedAt || 0;
  return now - asked < settings.startGraceSeconds ? 'join' : 'restart';
}

/** The fields of a new record (the job reads documentId, lang, source, fileName). */
function newRecord({ documentId, lang, doc, uid, now }) {
  const ext = (doc.kind || doc.source.split('.').pop() || '').toLowerCase();
  const title = (doc.title || '').trim();
  const fileName = title ? `${title}.${ext}` : (doc.fileName || `document.${ext}`);
  return {
    documentId,
    lang,
    source: doc.source,
    fileName,
    status: 'queued',
    requesters: [uid],
    jobRequestedAt: now,
  };
}

module.exports = { SETTINGS, FINISHED, recordId, checkRequest, checkDocument, decide, newRecord };
