// Document translation: what the app reads and the one call it makes.
//
// Firestore rules this relies on (firestore.rules):
//   documents/{id}       read if signed in and status == 'published'
//   translations/{id}    read if signed in; written only by the server
//   config/{doc}         read by anyone
//   uploaders/{uid}      the user may read their own entry (shows the Upload button)
// Storage rules (storage.rules): documents/ and translations/ readable when signed in;
// uploads/{uid}/ writable by its owner (PDF/Word, at most 50 MB).

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/translatable_document.dart';
import '../models/translation_record.dart';

class TranslationService {
  final _db = FirebaseFirestore.instance;
  // same region as the function (functions/index.js, TRANSLATION.region)
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Published documents, by title.
  Stream<List<TranslatableDocument>> documents() {
    return _db
        .collection('documents')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(TranslatableDocument.fromFirestore).toList();
      list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      return list;
    });
  }

  Stream<TranslatableDocument?> document(String id) {
    return _db.collection('documents').doc(id).snapshots().map(
        (doc) => doc.exists ? TranslatableDocument.fromFirestore(doc) : null);
  }

  /// The languages the service offers, by name (config/translation, published from the
  /// translation engine's own list).
  Future<List<TranslationLanguage>> languages() async {
    final doc = await _db.collection('config').doc('translation').get();
    final raw = (doc.data()?['languages'] as List<dynamic>?) ?? const [];
    final list = raw
        .whereType<Map>()
        .map((m) => TranslationLanguage(
              code: m['code'] as String? ?? '',
              name: m['name'] as String? ?? '',
            ))
        .where((l) => l.code.isNotEmpty)
        .toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// Every translation record of a document (to show which languages exist already).
  Stream<Map<String, TranslationRecord>> translationsOf(String documentId) {
    return _db
        .collection('translations')
        .where('documentId', isEqualTo: documentId)
        .snapshots()
        .map((snap) => {
              for (final d in snap.docs)
                (d.data()['lang'] as String? ?? ''): TranslationRecord.fromFirestore(d),
            });
  }

  /// Asks for the document in a language. The server serves it from the cache, joins a
  /// translation already running, or starts one; the record then changes by itself.
  /// Throws FirebaseFunctionsException with a message for the user on refusal.
  Future<void> request(String documentId, String lang) async {
    await _functions
        .httpsCallable('requestTranslation')
        .call({'documentId': documentId, 'lang': lang});
  }

  /// Largest file that can be uploaded (same limit as storage.rules and the function).
  static const maxUploadBytes = 50 * 1024 * 1024;

  /// Whether the signed-in user may upload documents.
  Stream<bool> isUploader() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);
    return _db.collection('uploaders').doc(uid).snapshots().map((d) => d.exists).handleError((_) => false);
  }

  /// Uploads a PDF or Word file and publishes it as a document; returns its id.
  /// onProgress gets 0..1 while the file is sent.
  Future<String> upload({
    required PlatformFile file,
    required String title,
    void Function(double)? onProgress,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('not signed in');
    final ext = (file.extension ?? '').toLowerCase();
    if (ext != 'pdf' && ext != 'docx') throw ArgumentError('only PDF or Word (.docx) files');
    final ref = FirebaseStorage.instance.ref('uploads/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext');
    final meta = SettableMetadata(
      contentType: ext == 'pdf'
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
    final path = file.path;
    final task = path != null ? ref.putFile(File(path), meta) : ref.putData(await file.readAsBytes(), meta);
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    });
    try {
      await task;
    } finally {
      await sub.cancel();
    }
    final result = await _functions
        .httpsCallable('publishDocument', options: HttpsCallableOptions(timeout: const Duration(minutes: 2)))
        .call({'uploadPath': ref.fullPath, 'title': title, 'fileName': file.name});
    return (result.data as Map)['documentId'] as String;
  }

  /// Removes a document the user uploaded, with all its translations.
  Future<void> delete(String documentId) async {
    await _functions
        .httpsCallable('deleteDocument', options: HttpsCallableOptions(timeout: const Duration(minutes: 2)))
        .call({'documentId': documentId});
  }

  /// A link to the result file (valid until the file is replaced).
  Future<String> downloadUrl(String storagePath) {
    return FirebaseStorage.instance.ref(storagePath).getDownloadURL();
  }
}
