// Tests for requestTranslation on an in-memory Firestore and a fake job starter.
// Run: cd functions && npm test   (Node's built-in test runner, no extra packages)
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const L = require('../translation/logic');
const { requestTranslation, RequestError } = require('../translation/request');

const LANGS = [{ code: 'ro', name: 'Romanian' }, { code: 'de', name: 'German' }];
const DOC = { title: 'Basic Faith Conversation 1', source: 'documents/bfc1/source.docx',
  kind: 'docx', sourceLang: 'en', status: 'published' };

function fakeDb(initial = {}) {
  const data = JSON.parse(JSON.stringify(initial));
  const ref = (path) => ({
    path,
    get: async () => ({ exists: path in data, data: () => structuredClone(data[path]) }),
    update: async (u) => { data[path] = { ...data[path], ...u }; },
  });
  return {
    data,
    doc: ref,
    runTransaction: async (fn) => {
      const writes = [];
      const tx = {
        get: (r) => r.get(),
        set: (r, v) => writes.push(() => { data[r.path] = v; }),
        update: (r, v) => writes.push(() => { data[r.path] = { ...data[r.path], ...v }; }),
      };
      const out = await fn(tx);
      writes.forEach((w) => w());
      return out;
    },
  };
}

function deps(db, extra = {}) {
  const started = [];
  return {
    started,
    db,
    runJob: async (rid) => { started.push(rid); },
    languages: async () => LANGS,
    now: () => 1000,
    timestamp: () => 'TS',
    log: () => {},
    ...extra,
  };
}

const REC = 'translations/bfc1__ro';

test('decide covers every status', () => {
  assert.equal(L.decide(null, 1000), 'create');
  for (const s of ['ready', 'needs_review', 'refused']) assert.equal(L.decide({ status: s }, 1000), 'served');
  assert.equal(L.decide({ status: 'failed' }, 1000), 'failed');
  assert.equal(L.decide({ status: 'running', leaseUntil: 2000 }, 1000), 'join');
  assert.equal(L.decide({ status: 'running', leaseUntil: 999 }, 1000), 'restart');
  assert.equal(L.decide({ status: 'queued', jobRequestedAt: 900 }, 1000), 'join');
  assert.equal(L.decide({ status: 'queued', jobRequestedAt: 0 }, 1000), 'restart');
  assert.equal(L.decide({ status: 'queued', jobRequestedAt: 1000 - L.SETTINGS.startGraceSeconds }, 1000), 'restart');
});

test('first request creates the record and starts the job', async () => {
  const db = fakeDb({ 'documents/bfc1': DOC });
  const d = deps(db);
  const out = await requestTranslation('u1', { documentId: 'bfc1', lang: 'ro' }, d);
  assert.deepEqual(out, { recordId: 'bfc1__ro', status: 'queued', action: 'create' });
  assert.deepEqual(d.started, ['bfc1__ro']);
  const rec = db.data[REC];
  assert.equal(rec.status, 'queued');
  assert.equal(rec.source, DOC.source);
  assert.equal(rec.fileName, 'Basic Faith Conversation 1.docx');
  assert.deepEqual(rec.requesters, ['u1']);
  assert.equal(rec.requestedAt, 'TS');
});

test('a second user joins the running job; nothing new starts', async () => {
  const db = fakeDb({ 'documents/bfc1': DOC,
    [REC]: { status: 'running', leaseUntil: 5000, requesters: ['u1'] } });
  const d = deps(db);
  const out = await requestTranslation('u2', { documentId: 'bfc1', lang: 'ro' }, d);
  assert.equal(out.action, 'join');
  assert.deepEqual(d.started, []);
  assert.deepEqual(db.data[REC].requesters, ['u1', 'u2']);
});

test('a finished translation is served from the cache, at no cost', async () => {
  const db = fakeDb({ 'documents/bfc1': DOC, [REC]: { status: 'ready', requesters: ['u1'] } });
  const d = deps(db);
  const out = await requestTranslation('u1', { documentId: 'bfc1', lang: 'ro' }, d);
  assert.deepEqual(out, { recordId: 'bfc1__ro', status: 'ready', action: 'served' });
  assert.deepEqual(d.started, []);
  assert.deepEqual(db.data[REC].requesters, ['u1']);           // not added twice
});

test('a dead worker is restarted: record back to queued, job started again', async () => {
  const db = fakeDb({ 'documents/bfc1': DOC,
    [REC]: { status: 'running', leaseUntil: 10, attempts: 1, requesters: ['u1'] } });
  const d = deps(db);
  const out = await requestTranslation('u1', { documentId: 'bfc1', lang: 'ro' }, d);
  assert.equal(out.action, 'restart');
  assert.equal(out.status, 'queued');
  assert.deepEqual(d.started, ['bfc1__ro']);
  assert.equal(db.data[REC].attempts, 1);                     // the job counts attempts
  assert.equal(db.data[REC].jobRequestedAt, 1000);
});

test('a failed translation is not re-run by users', async () => {
  const db = fakeDb({ 'documents/bfc1': DOC, [REC]: { status: 'failed', requesters: ['u1'] } });
  const d = deps(db);
  const out = await requestTranslation('u2', { documentId: 'bfc1', lang: 'ro' }, d);
  assert.equal(out.action, 'failed');
  assert.deepEqual(d.started, []);
});

test('if the job cannot start, the user gets an error and the next request retries', async () => {
  const db = fakeDb({ 'documents/bfc1': DOC });
  const d = deps(db, { runJob: async () => { throw new Error('PERMISSION_DENIED'); } });
  await assert.rejects(requestTranslation('u1', { documentId: 'bfc1', lang: 'ro' }, d),
    (e) => e instanceof RequestError && e.code === 'unavailable');
  assert.equal(db.data[REC].jobRequestedAt, 0);
  assert.equal(L.decide(db.data[REC], 1000), 'restart');
});

test('requests that must be refused', async () => {
  const db = fakeDb({
    'documents/bfc1': DOC,
    'documents/draft': { ...DOC, status: 'draft', source: 'documents/draft/source.docx' },
    'documents/odd': { ...DOC, source: 'somewhere/else.docx' },
    'documents/rodoc': { ...DOC, sourceLang: 'ro', source: 'documents/rodoc/source.docx' },
  });
  const code = async (uid, data) => {
    try { await requestTranslation(uid, data, deps(db)); return 'ok'; } catch (e) { return e.code; }
  };
  assert.equal(await code(null, { documentId: 'bfc1', lang: 'ro' }), 'unauthenticated');
  assert.equal(await code('u1', { documentId: '../x', lang: 'ro' }), 'invalid-argument');
  assert.equal(await code('u1', { documentId: 'bfc1', lang: 'xx' }), 'invalid-argument');
  assert.equal(await code('u1', { documentId: 'rodoc', lang: 'ro' }), 'invalid-argument');
  assert.equal(await code('u1', { documentId: 'nope', lang: 'ro' }), 'not-found');
  assert.equal(await code('u1', { documentId: 'draft', lang: 'ro' }), 'failed-precondition');
  assert.equal(await code('u1', { documentId: 'odd', lang: 'ro' }), 'failed-precondition');
  assert.equal(await code('u1', {}), 'invalid-argument');
});

test('daily limit: new jobs stop at the limit; cached results are always served', async () => {
  const day = L.usageDay(1000);
  const db = fakeDb({ 'documents/bfc1': DOC, [`usage/${day}`]: { jobs: 2 },
    'translations/bfc1__de': { status: 'ready', requesters: ['u1'] } });
  const d = deps(db, { dailyLimit: async () => 3 });
  await requestTranslation('u1', { documentId: 'bfc1', lang: 'ro' }, d);       // job 3 of 3
  assert.equal(db.data[`usage/${day}`].jobs, 3);
  db.data[REC] = undefined; delete db.data[REC];
  const d2 = deps(db, { dailyLimit: async () => 3 });
  await assert.rejects(requestTranslation('u2', { documentId: 'bfc1', lang: 'ro' }, d2),
    (e) => e.code === 'resource-exhausted');
  assert.deepEqual(d2.started, []);
  const out = await requestTranslation('u2', { documentId: 'bfc1', lang: 'de' }, d2);
  assert.equal(out.action, 'served');                                       // cache: no limit
  assert.equal(db.data[`usage/${day}`].jobs, 3);
});
