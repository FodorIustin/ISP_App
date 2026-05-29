import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/lesson_service.dart';

class LessonResultsScreen extends StatefulWidget {
  const LessonResultsScreen({super.key, required this.lessonId});
  final String lessonId;

  @override
  State<LessonResultsScreen> createState() => _LessonResultsScreenState();
}

class _LessonResultsScreenState extends State<LessonResultsScreen> {
  final _service = LessonService();

  bool _loading = true;
  int _readingPoints = 0;
  int _answerPoints = 0;
  String _lessonTitle = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lesson = await _service.getLessonById(widget.lessonId);
    final results = await _service.getLessonResults(widget.lessonId);

    if (!mounted) return;
    setState(() {
      _readingPoints = lesson?.pointsForReading ?? 0;
      _answerPoints = (results['answerPoints'] as int?) ?? 0;
      _lessonTitle = lesson?.titleEn ?? '';
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final total = _readingPoints + _answerPoints;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // Trophy circle
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xfff0f5ff),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.emoji_events,
                      size: 44, color: Color(0xfff9b625)),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Lesson Complete!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff0f1923),
                ),
              ),

              if (_lessonTitle.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _lessonTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xff888888)),
                ),
              ],

              const SizedBox(height: 24),

              // Score card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xfff8f7f4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Points earned this lesson',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12, color: Color(0xff888888)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff003e6d),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text('Reading: +${_readingPoints}pts',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff888888))),
                        Text('Answers: +${_answerPoints}pts',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff888888))),
                        Text('Total: ${total}pts',
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xff888888))),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Country standing (hardcoded until ranking logic is built)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xfff8f7f4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Romania is now #2',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff0f1923),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: const LinearProgressIndicator(
                        value: 0.8,
                        backgroundColor: Color(0xffe0ddd6),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xff003e6d)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '18 pts behind #1',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xff888888)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Primary button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff003e6d),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Back to lessons',
                      style: TextStyle(fontSize: 15)),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  'View leaderboard',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xff007398)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
