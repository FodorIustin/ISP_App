import 'package:cloud_firestore/cloud_firestore.dart';

/// A document users can ask to have translated: Firestore `documents/{id}`.
/// Only published documents are visible to the app (firestore.rules).
class TranslatableDocument {
  final String id;
  final String title;
  final String fileName;
  final String kind; // 'pdf' | 'docx'
  final String sourceLang;
  final bool test;

  /// uid of the person who uploaded it (null for documents added by script).
  final String? uploadedBy;

  const TranslatableDocument({
    required this.id,
    required this.title,
    required this.fileName,
    required this.kind,
    required this.sourceLang,
    required this.test,
    this.uploadedBy,
  });

  factory TranslatableDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? const {};
    return TranslatableDocument(
      id: doc.id,
      title: data['title'] as String? ?? doc.id,
      fileName: data['fileName'] as String? ?? '',
      kind: data['kind'] as String? ?? '',
      sourceLang: data['sourceLang'] as String? ?? 'en',
      test: data['test'] as bool? ?? false,
      uploadedBy: data['uploadedBy'] as String?,
    );
  }
}

/// A language the translation service offers (Firestore `config/translation`).
class TranslationLanguage {
  final String code;
  final String name;

  const TranslationLanguage({required this.code, required this.name});
}
