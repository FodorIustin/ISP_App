import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/translatable_document.dart';
import '../providers/translation_providers.dart';

const _royalBlue = Color(0xFF003E6D);

/// The documents users can read in their own language.
class DocumentsScreen extends ConsumerWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(documentsProvider);
    final canUpload = ref.watch(isUploaderProvider).value ?? false;
    return Scaffold(
      floatingActionButton: canUpload
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/documents/upload'),
              backgroundColor: _royalBlue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload'),
            )
          : null,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: Colors.white,
        foregroundColor: _royalBlue,
        elevation: 0,
      ),
      body: docs.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Message('Documents could not be loaded.\n$e'),
        data: (list) => list.isEmpty
            ? const _Message('No documents yet.')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _DocumentTile(doc: list[i]),
              ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.doc});
  final TranslatableDocument doc;

  @override
  Widget build(BuildContext context) {
    final isPdf = doc.kind == 'pdf';
    return Material(
      color: const Color(0xFFF5F7FA),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/documents/${doc.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
                  color: _royalBlue, size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600, color: _royalBlue)),
                    const SizedBox(height: 4),
                    Text(
                      '${isPdf ? 'PDF' : 'Word'} · original in ${doc.sourceLang.toUpperCase()}'
                      '${doc.test ? ' · test document' : ''}',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.translate, color: _royalBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54)),
        ),
      );
}
