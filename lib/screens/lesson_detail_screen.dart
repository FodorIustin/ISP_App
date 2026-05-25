// IMPORTANT: Add these rules to Firebase Console → Firestore → Rules:
// match /userProgress/{doc} {
//   allow read, write: if request.auth != null;
// }
// match /lessons/{doc} {
//   allow read: if request.auth != null;
//   allow write: if false;
// }

import 'package:flutter/material.dart';

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

  Lesson? _lesson;
  bool _isCompleted = false;
  double _readProgress = 0.0;
  double _lastSavedProgress = 0.0;
  bool _loading = true;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lessonFuture = _service.getLesson(widget.lessonId);
    final completedFuture = _service.isLessonCompleted(widget.lessonId);
    final progressFuture = _service.getLessonProgress(widget.lessonId);

    final lesson = await lessonFuture;
    final isCompleted = await completedFuture;
    final progress = await progressFuture;

    if (!mounted) return;
    setState(() {
      _lesson = lesson;
      _isCompleted = isCompleted;
      _readProgress = isCompleted ? 1.0 : progress;
      _lastSavedProgress = _readProgress;
      _loading = false;
    });
  }

  bool _onScroll(ScrollNotification notification) {
    final max = notification.metrics.maxScrollExtent;
    if (max <= 0) return false;
    final progress =
        (notification.metrics.pixels / max).clamp(0.0, 1.0);
    if (progress > _readProgress) {
      setState(() => _readProgress = progress);
      if (progress - _lastSavedProgress >= 0.1) {
        _lastSavedProgress = progress;
        _service.markLessonProgress(widget.lessonId, progress);
      }
    }
    return false;
  }

  Future<void> _markComplete() async {
    if (_completing) return;
    setState(() => _completing = true);
    await _service.markLessonCompleted(widget.lessonId);
    if (!mounted) return;
    final points = _lesson?.pointsForReading ?? 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Lesson completed! +$points pts'),
        backgroundColor: const Color(0xfff9b625),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xff003e6d),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final lesson = _lesson;
    if (lesson == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xff003e6d),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Lesson not found.',
              style: TextStyle(color: Color(0xff888888))),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff003e6d),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          lesson.getTitle('en'),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // Animated progress bar
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
                      width: constraints.maxWidth * _readProgress,
                      color: const Color(0xfff9b625),
                    ),
                  ],
                ),
              );
            },
          ),
          // Scrollable content
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAY ${lesson.dayNumber}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff007398),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lesson.getTitle('en'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff0f1923),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (lesson.imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          lesson.imageUrl,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      lesson.getContent('en'),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff3d3d3a),
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Callout box
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFfffbf2),
                        border: Border(
                          left: BorderSide(
                              color: Color(0xfff9b625), width: 3),
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: const Text(
                        'Equipping Educators to Change the World — ISP',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff5a4a1a),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Bottom action
                    if (_isCompleted)
                      _CompletedBanner(points: lesson.pointsForReading)
                    else if (_readProgress >= 0.8)
                      _MarkCompleteButton(
                        loading: _completing,
                        onTap: _markComplete,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Completed Banner ─────────────────────────────────────────────────────────

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner({required this.points});
  final int points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            'Completed · $points pts earned',
            style: const TextStyle(
                fontSize: 13, color: Color(0xff2e7d32)),
          ),
        ],
      ),
    );
  }
}

// ─── Mark Complete Button ─────────────────────────────────────────────────────

class _MarkCompleteButton extends StatelessWidget {
  const _MarkCompleteButton({required this.onTap, required this.loading});
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff003e6d),
          disabledBackgroundColor: Colors.grey.shade300,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Text('Mark as complete',
                style: TextStyle(fontSize: 15)),
      ),
    );
  }
}
