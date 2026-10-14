import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/translatable_document.dart';
import '../models/translation_record.dart';
import '../services/translation_service.dart';

final translationServiceProvider = Provider<TranslationService>((ref) => TranslationService());

/// Published documents (Documents screen).
final documentsProvider = StreamProvider.autoDispose<List<TranslatableDocument>>(
  (ref) => ref.watch(translationServiceProvider).documents(),
);

final documentProvider = StreamProvider.autoDispose.family<TranslatableDocument?, String>(
  (ref, id) => ref.watch(translationServiceProvider).document(id),
);

/// Languages offered (config/translation); kept for the session.
final translationLanguagesProvider = FutureProvider<List<TranslationLanguage>>(
  (ref) => ref.watch(translationServiceProvider).languages(),
);

/// lang code -> record, for one document, live.
final documentTranslationsProvider =
    StreamProvider.autoDispose.family<Map<String, TranslationRecord>, String>(
  (ref, documentId) => ref.watch(translationServiceProvider).translationsOf(documentId),
);

/// Whether the signed-in user may upload documents (uploaders/{uid}).
final isUploaderProvider = StreamProvider.autoDispose<bool>(
  (ref) => ref.watch(translationServiceProvider).isUploader(),
);
