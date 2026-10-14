import 'package:cloud_firestore/cloud_firestore.dart';

/// One translation of one document into one language: Firestore
/// `translations/{documentId}__{lang}`. Written only by the server; the app follows it.
///
/// Status: queued -> running -> ready | needsReview | refused | failed.
enum TranslationStatus { queued, running, ready, needsReview, refused, failed, unknown }

class TranslationRecord {
  final String id;
  final String documentId;
  final String lang;
  final TranslationStatus status;

  /// true = made by the fake translator (testing, before the real service is on).
  final bool test;

  /// Storage paths of the results: keys pdf, docx (and job, translations, ...).
  final Map<String, String> files;

  /// Why a translation needs a person's check or was refused.
  final List<String> reasons;
  final String? error;

  const TranslationRecord({
    required this.id,
    required this.documentId,
    required this.lang,
    required this.status,
    required this.test,
    required this.files,
    required this.reasons,
    required this.error,
  });

  bool get inProgress =>
      status == TranslationStatus.queued || status == TranslationStatus.running;

  /// A result the user can open (needs_review is shown, labelled "Not yet checked",
  /// during testing; before real users it is hidden until an admin approves it).
  bool get hasResult =>
      (status == TranslationStatus.ready || status == TranslationStatus.needsReview) &&
      (files['pdf'] != null || files['docx'] != null);

  /// The file to open: the PDF when there is one (same look on every phone), else Word.
  String? get resultPath => files['pdf'] ?? files['docx'];

  static TranslationStatus _status(String? s) => switch (s) {
        'queued' => TranslationStatus.queued,
        'running' => TranslationStatus.running,
        'ready' => TranslationStatus.ready,
        'needs_review' => TranslationStatus.needsReview,
        'refused' => TranslationStatus.refused,
        'failed' => TranslationStatus.failed,
        _ => TranslationStatus.unknown,
      };

  factory TranslationRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    final files = <String, String>{};
    final rawFiles = data['files'];
    if (rawFiles is Map) {
      rawFiles.forEach((k, v) {
        if (k is String && v is String) files[k] = v;
      });
    }
    return TranslationRecord(
      id: doc.id,
      documentId: data['documentId'] as String? ?? '',
      lang: data['lang'] as String? ?? '',
      status: _status(data['status'] as String?),
      test: data['test'] as bool? ?? false,
      files: files,
      reasons: (data['reasons'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      error: data['error'] as String?,
    );
  }
}
