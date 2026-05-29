import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/lesson.dart';
import '../services/lesson_service.dart';

class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key});

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final _service = LessonService();
  StreamSubscription<List<Lesson>>? _sub;

  List<Lesson> _lessons = [];
  Map<String, bool> _completions = {};
  Map<String, double> _progress = {};
  Map<String, bool> _answered = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _sub = _service.getLessons().listen((lessons) {
      if (mounted) setState(() { _lessons = lessons; _loading = false; });
      _loadProgress(lessons);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress(List<Lesson> lessons) async {
    if (lessons.isEmpty) return;
    final completionFutures = lessons.map((l) => _service.isLessonCompleted(l.id));
    final progressFutures = lessons.map((l) => _service.getLessonProgress(l.id));
    final answeredFutures = lessons.map((l) => _service.hasAnsweredQuestions(l.id));
    final completions = await Future.wait(completionFutures);
    final progressMaps = await Future.wait(progressFutures);
    final answered = await Future.wait(answeredFutures);
    if (!mounted) return;
    setState(() {
      _completions = Map.fromIterables(lessons.map((l) => l.id), completions);
      _progress = Map.fromIterables(
        lessons.map((l) => l.id),
        progressMaps.map((m) => (m['progress'] as double?) ?? 0.0),
      );
      _answered = Map.fromIterables(lessons.map((l) => l.id), answered);
    });
  }

  void _navigateToLesson(String lessonId) {
    context.go('/lesson/$lessonId');
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completions.values.where((v) => v).length;
    final totalCount = _lessons.length;
    final progressFraction =
        totalCount > 0 ? completedCount / totalCount : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // Header
                    const Text(
                      'Lessons',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff0f1923),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ISP Europe Conference 2026',
                      style: TextStyle(fontSize: 12, color: Color(0xff888888)),
                    ),
                    const SizedBox(height: 14),
                    // Progress card
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xfff8f7f4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your progress',
                                  style: TextStyle(
                                      fontSize: 10, color: Color(0xff888888)),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: progressFraction,
                                    backgroundColor: const Color(0xffe0ddd6),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Color(0xff003e6d)),
                                    minHeight: 5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$completedCount/$totalCount',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff0f1923),
                                ),
                              ),
                              const Text(
                                'lessons',
                                style: TextStyle(
                                    fontSize: 10, color: Color(0xff888888)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Lessons list
                    Expanded(
                      child: _lessons.isEmpty
                          ? const Center(
                              child: Text(
                                'No lessons available yet',
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xff888888)),
                              ),
                            )
                          : ListView.separated(
                              itemCount: _lessons.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final lesson = _lessons[i];
                                final isCompleted =
                                    _completions[lesson.id] ?? false;
                                final progress = _progress[lesson.id] ?? 0.0;
                                final isInProgress =
                                    !isCompleted && progress > 0;

                                if (isCompleted) {
                                  return _CompletedCard(
                                    lesson: lesson,
                                    hasAnswered: _answered[lesson.id] ?? false,
                                  );
                                } else if (isInProgress) {
                                  return _InProgressCard(
                                    lesson: lesson,
                                    progress: progress,
                                    onTap: () =>
                                        _navigateToLesson(lesson.id),
                                  );
                                } else {
                                  return _NotStartedCard(
                                    lesson: lesson,
                                    onTap: () =>
                                        _navigateToLesson(lesson.id),
                                  );
                                }
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
      ),
    );
  }
}

// ─── Completed Card ───────────────────────────────────────────────────────────

class _CompletedCard extends StatelessWidget {
  const _CompletedCard({required this.lesson, required this.hasAnswered});
  final Lesson lesson;
  final bool hasAnswered;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => hasAnswered
          ? context.go('/lesson/${lesson.id}')
          : context.go('/lesson-questions/${lesson.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xfff8f7f4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xff003e6d),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check, color: Color(0xfff9b625), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Day ${lesson.dayNumber}',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xff888888)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xffe8f5e9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                              fontSize: 9, color: Color(0xff2e7d32)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lesson.getTitle('en'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff0f1923),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${lesson.totalQuestions} questions',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xff888888)),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.star,
                          color: Color(0xfff9b625), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${lesson.pointsForReading} pts earned',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xff888888)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasAnswered
                        ? 'Tap to re-read'
                        : 'Tap to answer questions',
                    style: TextStyle(
                      fontSize: 10,
                      color: hasAnswered
                          ? const Color(0xff888888)
                          : const Color(0xff007398),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── In Progress Card ─────────────────────────────────────────────────────────

class _InProgressCard extends StatelessWidget {
  const _InProgressCard({
    required this.lesson,
    required this.progress,
    required this.onTap,
  });
  final Lesson lesson;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff0f5ff),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff003e6d), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xff003e6d),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.book, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Day ${lesson.dayNumber}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xff007398)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xffe3f0ff),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'In progress',
                        style: TextStyle(
                            fontSize: 9, color: Color(0xff003e6d)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  lesson.getTitle('en'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0f1923),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${lesson.totalQuestions} questions',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xff007398)),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xffc8d8f0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xff003e6d)),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${(progress * 100).round()}% read',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xff007398)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xff003e6d),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Continue reading',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Not Started Card ─────────────────────────────────────────────────────────

class _NotStartedCard extends StatelessWidget {
  const _NotStartedCard({required this.lesson, required this.onTap});
  final Lesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xfff8f7f4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xff003e6d),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.book, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day ${lesson.dayNumber}',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xff888888)),
                ),
                const SizedBox(height: 3),
                Text(
                  lesson.getTitle('en'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0f1923),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${lesson.totalQuestions} questions',
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xff888888)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xff003e6d),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Start reading',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
