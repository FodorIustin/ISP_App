import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/translatable_document.dart';
import '../models/translation_record.dart';
import '../providers/translation_providers.dart';

const _royalBlue = Color(0xFF003E6D);
const _gold = Color(0xFFF9B625);
const _teal = Color(0xFF3EB1C8);

/// One document: pick a language, ask for it, follow it live, open the result.
class DocumentTranslateScreen extends ConsumerStatefulWidget {
  const DocumentTranslateScreen({super.key, required this.documentId});
  final String documentId;

  @override
  ConsumerState<DocumentTranslateScreen> createState() => _DocumentTranslateScreenState();
}

class _DocumentTranslateScreenState extends ConsumerState<DocumentTranslateScreen> {
  String? _lang;
  bool _sending = false;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _preselect();
  }

  /// Start with the language the user chose for the app, when the service offers it.
  Future<void> _preselect() async {
    final prefs = await SharedPreferences.getInstance();
    final chosen = (prefs.getString('selected_language') ?? '').toLowerCase();
    final langs = await ref.read(translationLanguagesProvider.future);
    if (!mounted || _lang != null || chosen.isEmpty) return;
    for (final l in langs) {
      if (l.code == chosen || l.name.toLowerCase().startsWith(chosen)) {
        setState(() => _lang = l.code);
        return;
      }
    }
  }

  Future<void> _request() async {
    final lang = _lang;
    if (lang == null) return;
    setState(() => _sending = true);
    try {
      await ref.read(translationServiceProvider).request(widget.documentId, lang);
    } on FirebaseFunctionsException catch (e) {
      _snack(e.message ?? 'The translation could not be requested.');
    } catch (e) {
      _snack('The translation could not be requested. Check your connection.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _open(TranslationRecord rec) async {
    final path = rec.resultPath;
    if (path == null) return;
    setState(() => _opening = true);
    try {
      final url = await ref.read(translationServiceProvider).downloadUrl(path);
      final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!ok) _snack('The file could not be opened.');
    } catch (e) {
      _snack('The file could not be opened.');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final doc = ref.watch(documentProvider(widget.documentId)).value;
    final langs = ref.watch(translationLanguagesProvider);
    final records = ref.watch(documentTranslationsProvider(widget.documentId)).value ?? const {};
    final selected = _lang == null ? null : records[_lang];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(doc?.title ?? 'Translate'),
        backgroundColor: Colors.white,
        foregroundColor: _royalBlue,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Choose a language. You get the same document, same layout, with the text '
                'translated automatically.',
                style: TextStyle(color: Colors.black54),
              ),
            ),
            Expanded(
              child: langs.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Languages could not be loaded.\n$e')),
                data: (list) => ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (context, i) => _LanguageRow(
                    language: list[i],
                    record: records[list[i].code],
                    selected: list[i].code == _lang,
                    disabled: doc != null && doc.sourceLang == list[i].code,
                    onTap: () => setState(() => _lang = list[i].code),
                  ),
                ),
              ),
            ),
            _StatusPanel(
              languageName: _languageName(langs.value, _lang),
              record: selected,
              sending: _sending,
              opening: _opening,
              onRequest: _request,
              onOpen: selected == null ? null : () => _open(selected),
            ),
          ],
        ),
      ),
    );
  }

  static String? _languageName(List<TranslationLanguage>? list, String? code) {
    if (list == null || code == null) return null;
    for (final l in list) {
      if (l.code == code) return l.name;
    }
    return code;
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.record,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });
  final TranslationLanguage language;
  final TranslationRecord? record;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: !disabled,
      selected: selected,
      selectedTileColor: _teal.withValues(alpha: 0.12),
      leading: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: _royalBlue),
      title: Text(language.name),
      trailing: disabled ? const Text('original') : _StatusChip(record: record),
      onTap: disabled ? null : onTap,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.record});
  final TranslationRecord? record;

  @override
  Widget build(BuildContext context) {
    final r = record;
    if (r == null) return const SizedBox.shrink();
    final (text, color) = switch (r.status) {
      TranslationStatus.ready => ('Ready', Colors.green),
      TranslationStatus.needsReview => ('Not yet checked', _gold),
      TranslationStatus.queued || TranslationStatus.running => ('In progress', _teal),
      TranslationStatus.refused => ('Not possible', Colors.black45),
      TranslationStatus.failed => ('Failed', Colors.redAccent),
      TranslationStatus.unknown => ('', Colors.transparent),
    };
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: _royalBlue)),
    );
  }
}

/// The selected language: what is happening and what the user can do.
class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.languageName,
    required this.record,
    required this.sending,
    required this.opening,
    required this.onRequest,
    required this.onOpen,
  });
  final String? languageName;
  final TranslationRecord? record;
  final bool sending;
  final bool opening;
  final VoidCallback onRequest;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final name = languageName;
    final children = <Widget>[];

    if (name == null) {
      children.add(const Text('Choose a language above.'));
    } else if (r == null) {
      children.add(_button('Translate into $name', sending ? null : onRequest, busy: sending));
    } else if (r.inProgress) {
      children.addAll([
        Row(children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              r.status == TranslationStatus.queued
                  ? 'Starting the translation into $name…'
                  : 'Translating into $name…',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ]),
        const SizedBox(height: 6),
        const Text(
          'Usually 2–6 minutes. You can leave this screen; the translation continues and '
          'will be here when you come back.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
      ]);
    } else if (r.hasResult) {
      if (r.status == TranslationStatus.needsReview) {
        children.add(_note(
            'Not yet checked: this automatic translation has not been reviewed by a person yet.',
            _gold));
      }
      if (r.test) {
        children.add(_note(
            'Test translation: placeholder text, made to test the layout. Not a real translation.',
            _teal));
      }
      children.add(_button('Open $name translation', opening ? null : onOpen, busy: opening));
    } else if (r.status == TranslationStatus.refused) {
      children.add(_note(
          'This document cannot be translated automatically'
          '${r.reasons.isNotEmpty ? ': ${r.reasons.first}' : '.'}',
          Colors.black26));
    } else if (r.status == TranslationStatus.failed) {
      children.add(_note('The translation into $name failed. Please tell the ISP team.',
          Colors.redAccent));
    } else {
      children.add(const Text('Unknown state, please try again later.'));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
          children: children),
    );
  }

  static Widget _note(String text, Color color) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text, style: const TextStyle(fontSize: 13)),
      );

  static Widget _button(String label, VoidCallback? onPressed, {bool busy = false}) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _royalBlue,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: onPressed,
          child: busy
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(label),
        ),
      );
}
