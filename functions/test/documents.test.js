// Tests for publishDocument / deleteDocument on in-memory Firestore and Storage.
'use strict';

const test = require('node:test');
const assert = require('node:assert/strict');
const { sniff, cleanTitle, publishDocument, deleteDocument } = require('../translation/documents');

const PDF = Buffer.from('%PDF-1.7\n%âãÏÓ\n1 0 obj << >> endobj\n');
// minimal zip local header followed by the entry name a Word file always has
const DOCX = Buffer.concat([Buffer.from([0x50, 0x4b, 0x03, 0x04]), Buffer.alloc(26),
  Buffer.from('word/document.xml'), Buffer.alloc(32)]);
const XLSX = Buffer.concat([Buffer.from([0x50, 0x4b, 0x03, 0x04]), Buffer.alloc(26),
  Buffer.from('xl/workbook.xml'), Buffer.alloc(32)]);

function env({ uploader = true, files = {}, docs = {} } = {}) {
  const store = { ...files };
  const data = { ...docs };
  if (uploader) data['uploaders/u1'] = { since: 'x' };
  const ref = (path) => ({
    get: async () => ({ exists: path in data, data: () => data[path] }),
    set: async (v) => { data[path] = v; },
    delete: async () => { delete data[path]; },
  });
  let n = 0;
  return {
    store,
    data,
    deps: {
      db: {
        doc: ref,
        translationsOf: async (id) => Object.keys(data)
          .filter((k) => k.startsWith('translations/') && data[k].documentId === id).map(ref),
      },
      storage: {
        size: async (p) => (p in store ? store[p].length : null),
        read: async (p) => store[p],
        copy: async (a, b) => { store[b] = store[a]; },
        delete: async (p) => { delete store[p]; },
        deletePrefix: async (pre) => { for (const k of Object.keys(store)) if (k.startsWith(pre)) delete store[k]; },
      },
      newId: () => `doc${++n}`,
      timestamp: () => 'TS',
      log: () => {},
    },
  };
}

const code = async (p) => { try { await p; return 'ok'; } catch (e) { return e.code; } };

test('file type comes from the bytes, not the name', () => {
  assert.equal(sniff(PDF), 'pdf');
  assert.equal(sniff(DOCX), 'docx');
  assert.equal(sniff(XLSX), null);
  assert.equal(sniff(Buffer.from('hello world, not a document')), null);
});

test('title: given, else from the file name; trimmed', () => {
  assert.equal(cleanTitle('  Advent   guide ', 'x.pdf'), 'Advent guide');
  assert.equal(cleanTitle('', 'Leader Notes.docx'), 'Leader Notes');
  assert.equal(cleanTitle('x'.repeat(400), '').length, 150);
});

test('an uploader publishes a PDF: moved, recorded, staging copy removed', async () => {
  const e = env({ files: { 'uploads/u1/171.pdf': PDF } });
  const out = await publishDocument('u1', { uploadPath: 'uploads/u1/171.pdf', title: 'Guide',
    fileName: 'Guide.pdf' }, e.deps);
  assert.deepEqual(out, { documentId: 'doc1' });
  assert.ok(e.store['documents/doc1/source.pdf']);
  assert.equal(e.store['uploads/u1/171.pdf'], undefined);
  const d = e.data['documents/doc1'];
  assert.equal(d.status, 'published');
  assert.equal(d.kind, 'pdf');
  assert.equal(d.source, 'documents/doc1/source.pdf');
  assert.equal(d.uploadedBy, 'u1');
  assert.equal(d.sourceLang, 'en');
});

test('a .pdf that is really something else is rejected and removed', async () => {
  const e = env({ files: { 'uploads/u1/1.pdf': XLSX } });
  assert.equal(await code(publishDocument('u1', { uploadPath: 'uploads/u1/1.pdf' }, e.deps)),
    'invalid-argument');
  assert.equal(e.store['uploads/u1/1.pdf'], undefined);
  assert.equal(Object.keys(e.data).filter((k) => k.startsWith('documents/')).length, 0);
});

test('only uploaders, only their own staging folder', async () => {
  const notUploader = env({ uploader: false, files: { 'uploads/u1/1.pdf': PDF } });
  assert.equal(await code(publishDocument('u1', { uploadPath: 'uploads/u1/1.pdf' }, notUploader.deps)),
    'permission-denied');
  const e = env({ files: { 'uploads/u2/1.pdf': PDF } });
  assert.equal(await code(publishDocument('u1', { uploadPath: 'uploads/u2/1.pdf' }, e.deps)),
    'invalid-argument');
  assert.equal(await code(publishDocument('u1', { uploadPath: 'uploads/u1/../x.pdf' }, e.deps)),
    'invalid-argument');
  assert.equal(await code(publishDocument(null, { uploadPath: 'uploads/u1/1.pdf' }, e.deps)),
    'unauthenticated');
  assert.equal(await code(publishDocument('u1', { uploadPath: 'uploads/u1/missing.pdf' }, e.deps)),
    'not-found');
});

test('delete removes the document, its files and every translation', async () => {
  const e = env({
    files: { 'documents/d1/source.pdf': PDF, 'translations/d1/ro/x.pdf': PDF,
      'translations/d2/ro/x.pdf': PDF },
    docs: {
      'documents/d1': { uploadedBy: 'u1' },
      'translations/d1__ro': { documentId: 'd1' },
      'translations/d1__de': { documentId: 'd1' },
      'translations/d2__ro': { documentId: 'd2' },
    },
  });
  const out = await deleteDocument('u1', { documentId: 'd1' }, e.deps);
  assert.equal(out.translations, 2);
  assert.equal(e.data['documents/d1'], undefined);
  assert.equal(e.data['translations/d1__ro'], undefined);
  assert.ok(e.data['translations/d2__ro']);                     // other documents untouched
  assert.deepEqual(Object.keys(e.store), ['translations/d2/ro/x.pdf']);
});

test('only the uploader of a document can delete it', async () => {
  const e = env({ docs: { 'documents/d1': { uploadedBy: 'someone-else' } } });
  assert.equal(await code(deleteDocument('u1', { documentId: 'd1' }, e.deps)), 'permission-denied');
  assert.ok(e.data['documents/d1']);
});
