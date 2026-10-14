import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/translation_providers.dart';
import '../services/translation_service.dart';

const _royalBlue = Color(0xFF003E6D);

/// Upload a PDF or Word document so people can read it in their language.
class UploadDocumentScreen extends ConsumerStatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  ConsumerState<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends ConsumerState<UploadDocumentScreen> {
  final _title = TextEditingController();
  PlatformFile? _file;
  int? _size;
  double? _progress; // null = not uploading
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf', 'docx']);
    if (f == null || !mounted) return;
    final ext = (f.extension ?? '').toLowerCase();
    final size = await f.length();
    if (!mounted) return;
    setState(() {
      _error = null;
      if (ext != 'pdf' && ext != 'docx') {
        _error = 'Only PDF and Word (.docx) files can be uploaded.';
        return;
      }
      if (size != null && size > TranslationService.maxUploadBytes) {
        _error = 'The file is larger than 50 MB.';
        return;
      }
      _file = f;
      _size = size;
      if (_title.text.trim().isEmpty) {
        _title.text = f.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      }
    });
  }

  Future<void> _upload() async {
    final f = _file;
    if (f == null || _title.text.trim().isEmpty) return;
    setState(() {
      _progress = 0;
      _error = null;
    });
    try {
      final id = await ref.read(translationServiceProvider).upload(
            file: f,
            title: _title.text.trim(),
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      if (!mounted) return;
      context.pushReplacement('/documents/$id');
    } on FirebaseFunctionsException catch (e) {
      setState(() => _error = e.message ?? 'The document could not be published.');
    } catch (e) {
      setState(() => _error = 'The upload failed. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _progress = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _progress != null;
    final f = _file;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Upload a document'),
        backgroundColor: Colors.white,
        foregroundColor: _royalBlue,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'PDF or Word (.docx), in English, up to 50 MB. Everyone signed in to the app '
              'will see it in Documents and can ask for it in their language.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: busy ? null : _pick,
              icon: const Icon(Icons.attach_file),
              label: Text(f == null ? 'Choose a file' : 'Choose another file'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _royalBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            if (f != null) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  (f.extension ?? '').toLowerCase() == 'pdf'
                      ? Icons.picture_as_pdf_outlined
                      : Icons.description_outlined,
                  color: _royalBlue,
                ),
                title: Text(f.name),
                subtitle: _size == null ? null : Text(_formatSize(_size!)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _title,
                enabled: !busy,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Title shown in the app',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 20),
            if (busy) ...[
              LinearProgressIndicator(value: _progress! < 1 ? _progress : null),
              const SizedBox(height: 8),
              Text(
                _progress! < 1
                    ? 'Uploading… ${(100 * _progress!).round()}%'
                    : 'Checking and publishing…',
                style: const TextStyle(color: Colors.black54),
              ),
            ] else
              FilledButton(
                onPressed: f == null || _title.text.trim().isEmpty ? null : _upload,
                style: FilledButton.styleFrom(
                  backgroundColor: _royalBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Upload and publish'),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
