import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/lesson.dart';
import '../services/lesson_service.dart';

class LessonCompleteScreen extends StatefulWidget {
  const LessonCompleteScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  State<LessonCompleteScreen> createState() => _LessonCompleteScreenState();
}

class _LessonCompleteScreenState extends State<LessonCompleteScreen> {
  final _service = LessonService();
  Lesson? _lesson;
  bool _loading = true;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lesson = await _service.getLessonById(widget.lessonId);
    if (!mounted) return;
    setState(() {
      _lesson = lesson;
      _loading = false;
    });
  }

  Future<void> _goToQuestions() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await _service.markLessonCompleted(widget.lessonId);
    if (!mounted) return;
    context.go('/lesson-questions/${widget.lessonId}');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final lesson = _lesson;
    final pts = lesson?.pointsForReading ?? 0;
    final title = lesson?.titleEn ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 24),
              _HeroCircle(),
              const SizedBox(height: 16),
              _ColorDots(),
              const SizedBox(height: 24),
              const Text(
                "You've finished reading!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff0f1923),
                ),
              ),
              if (title.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xff888888),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Great work! Now answer a few questions to earn your points.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xff888888),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _StatsCard(pointsForReading: pts),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _navigating ? null : _goToQuestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff003e6d),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _navigating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Answer questions',
                          style: TextStyle(fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  'Skip for now',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xff888888),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCircle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        color: Color(0xfff0f5ff),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.menu_book,
          size: 48,
          color: Color(0xff003e6d),
        ),
      ),
    );
  }
}

class _ColorDots extends StatelessWidget {
  static const _colors = [
    Color(0xfff9b625),
    Color(0xffdd7d1b),
    Color(0xff3eb1c8),
    Color(0xff007398),
    Color(0xff003e6d),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _colors.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _colors[i],
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.pointsForReading});
  final int pointsForReading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xfff8f7f4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                value: '$pointsForReading pts',
                label: 'for reading',
              ),
            ),
            const VerticalDivider(color: Color(0xffe0ddd6), width: 1),
            Expanded(
              child: _StatItem(
                value: '20 pts',
                label: 'per correct answer',
              ),
            ),
            const VerticalDivider(color: Color(0xffe0ddd6), width: 1),
            Expanded(
              child: _StatItem(
                value: '+5 pts',
                label: 'speed bonus',
                valueColor: Color(0xfff9b625),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    this.valueColor = const Color(0xff0f1923),
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xff888888),
          ),
        ),
      ],
    );
  }
}
