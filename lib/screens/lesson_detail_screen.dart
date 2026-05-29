import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/lesson.dart';
import '../services/lesson_service.dart';

class LessonDetailScreen extends StatefulWidget {
  const LessonDetailScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final _service = LessonService();
  final _scrollController = ScrollController();

  Lesson? _lesson;
  bool _loading = true;
  bool _isCompleted = false;
  bool _hasAnsweredQuestions = false;
  int _currentSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final lesson = await _service.getLessonById(widget.lessonId);
    final isCompleted = await _service.isLessonCompleted(widget.lessonId);
    final progressData = await _service.getLessonProgress(widget.lessonId);
    final hasAnswered = await _service.hasAnsweredQuestions(widget.lessonId);

    if (!mounted) return;
    setState(() {
      _lesson = lesson;
      _isCompleted = isCompleted;
      _hasAnsweredQuestions = hasAnswered;
      _currentSectionIndex =
          (progressData['currentSection'] as int).clamp(
            0,
            (lesson?.sections.length ?? 1) - 1,
          );
      _loading = false;
    });
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _goToNext() {
    final lesson = _lesson!;
    final nextIndex = _currentSectionIndex + 1;
    setState(() => _currentSectionIndex = nextIndex);
    _scrollToTop();
    _service.markLessonProgress(
      widget.lessonId,
      (nextIndex + 1) / lesson.sections.length,
      nextIndex,
    );
  }

  void _goToPrev() {
    setState(() => _currentSectionIndex = _currentSectionIndex - 1);
    _scrollToTop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(''),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final lesson = _lesson;
    if (lesson == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(''),
        body: const Center(
          child: Text('Lesson not found.',
              style: TextStyle(color: Color(0xff888888))),
        ),
      );
    }

    final sections = lesson.sections;
    final totalSections = sections.length;
    final section = sections[_currentSectionIndex];
    final isLastSection = _currentSectionIndex == totalSections - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(lesson.titleEn),
      body: Column(
        children: [
          _ProgressBar(
            current: _currentSectionIndex,
            total: totalSections,
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_currentSectionIndex > 0)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _goToPrev,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          '← Previous',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff888888),
                          ),
                        ),
                      ),
                    ),
                  if (_currentSectionIndex > 0) const SizedBox(height: 12),
                  _SectionContent(
                    section: section,
                    imageUrl: lesson.imageUrl,
                    isLastSection: isLastSection,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          _BottomNav(
            isLastSection: isLastSection,
            isCompleted: _isCompleted,
            hasAnsweredQuestions: _hasAnsweredQuestions,
            pointsForReading: lesson.pointsForReading,
            onNext: _goToNext,
            onFinishReading: () => context.go(
              '/lesson-complete/${widget.lessonId}',
            ),
            onViewQuestions: () => context.go(
              '/lesson-questions/${widget.lessonId}',
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: const Color(0xff003e6d),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go('/home'),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── Progress Bar ─────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.current, required this.total});
  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              height: 4,
              child: Stack(
                children: [
                  Container(
                    width: constraints.maxWidth,
                    color: const Color(0xffe0ddd6),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: constraints.maxWidth * (current + 1) / total,
                    color: const Color(0xfff9b625),
                  ),
                ],
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            'Section ${current + 1} of $total',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xff888888),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Section Content ──────────────────────────────────────────────────────────

class _SectionContent extends StatelessWidget {
  const _SectionContent({
    required this.section,
    required this.imageUrl,
    required this.isLastSection,
  });
  final LessonSection section;
  final String imageUrl;
  final bool isLastSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section.isMainTitle) ...[
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xfff0f5ff),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.menu_book,
                  size: 48,
                  color: Color(0x4d003e6d),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            section.titleEn,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Color(0xff0f1923),
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xffe3f0ff),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              section.titleEn,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xff003e6d),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        ..._buildParagraphs(section.contentEn),
        if (isLastSection) ...[
          const SizedBox(height: 24),
          _BibleCallout(text: _extractBibleVerse(section.contentEn)),
        ],
      ],
    );
  }

  List<Widget> _buildParagraphs(String content) {
    final versePattern = RegExp(
        r"'The harvest is great.*?Matthew 9:37-38'",
        dotAll: true);
    final cleanContent = content.replaceFirst(versePattern, '').trim();

    final paragraphs = cleanContent
        .split('\n\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final widgets = <Widget>[];
    for (var i = 0; i < paragraphs.length; i++) {
      widgets.add(
        Text(
          paragraphs[i],
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xff3d3d3a),
            height: 1.8,
          ),
        ),
      );
      if (i < paragraphs.length - 1) {
        widgets.add(const SizedBox(height: 16));
      }
    }
    return widgets;
  }

  String _extractBibleVerse(String content) {
    final match = RegExp(
      r"'The harvest is great.*?Matthew 9:37-38'",
      dotAll: true,
    ).firstMatch(content);
    if (match != null) return match.group(0)!.replaceAll("'", '');
    return 'The harvest is great, but the workers are few. So pray to the Lord who is in charge of the harvest; ask him to send more workers into his fields. — Matthew 9:37-38';
  }
}

class _BibleCallout extends StatelessWidget {
  const _BibleCallout({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFfffbf2),
        border: Border(
          left: BorderSide(color: Color(0xfff9b625), width: 3),
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xff5a4a1a),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.isLastSection,
    required this.isCompleted,
    required this.hasAnsweredQuestions,
    required this.pointsForReading,
    required this.onNext,
    required this.onFinishReading,
    required this.onViewQuestions,
  });

  final bool isLastSection;
  final bool isCompleted;
  final bool hasAnsweredQuestions;
  final int pointsForReading;
  final VoidCallback onNext;
  final VoidCallback onFinishReading;
  final VoidCallback onViewQuestions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xffeeeeee), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (!isLastSection) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff003e6d),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text(
            'Next section →',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    if (!isCompleted) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: onFinishReading,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xfff9b625),
            foregroundColor: const Color(0xff3d2800),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: const Text(
            "I've finished reading ✓",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final banner = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffe8f5e9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: Color(0xff2e7d32), size: 18),
          const SizedBox(width: 8),
          Text(
            'Completed · $pointsForReading pts earned',
            style: const TextStyle(fontSize: 13, color: Color(0xff2e7d32)),
          ),
        ],
      ),
    );

    if (hasAnsweredQuestions) {
      return banner;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        banner,
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: onViewQuestions,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff003e6d),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'View questions',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
