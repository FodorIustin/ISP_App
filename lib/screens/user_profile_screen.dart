import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../models/lesson.dart';
import '../services/lesson_service.dart';
import '../services/user_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.userId});
  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _db = FirebaseFirestore.instance;

  AppUser? _user;
  bool _loading = true;
  bool _notFound = false;
  int _completedCount = 0;
  int _countryRank = 0;
  List<Lesson> _lessons = [];
  Map<String, bool> _completions = {};

  StreamSubscription<List<Lesson>>? _lessonSub;
  StreamSubscription<List<Map<String, dynamic>>>? _lbSub;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _lessonSub?.cancel();
    _lbSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final userDoc = await _db.collection('users').doc(widget.userId).get();
    if (!mounted) return;

    if (!userDoc.exists) {
      setState(() {
        _loading = false;
        _notFound = true;
      });
      return;
    }

    final user = AppUser.fromFirestore(userDoc);
    final progressSnap = await _db
        .collection('userProgress')
        .where('userId', isEqualTo: widget.userId)
        .where('completed', isEqualTo: true)
        .get();
    if (!mounted) return;

    setState(() {
      _user = user;
      _completedCount = progressSnap.docs.length;
      _loading = false;
    });

    _lbSub = UserService().getCountryLeaderboard().listen((lb) {
      if (!mounted) return;
      int rank = 0;
      for (var i = 0; i < lb.length; i++) {
        if (lb[i]['country'] == user.country) {
          rank = i + 1;
          break;
        }
      }
      setState(() => _countryRank = rank);
    });

    _lessonSub = LessonService().getLessons().listen((lessons) async {
      if (!mounted) return;
      setState(() => _lessons = lessons);
      final completions = await Future.wait(
        lessons.map((l) => _isCompleted(l.id)),
      );
      if (!mounted) return;
      setState(() {
        _completions = Map.fromIterables(
          lessons.map((l) => l.id),
          completions,
        );
      });
    });
  }

  Future<bool> _isCompleted(String lessonId) async {
    final doc = await _db
        .collection('userProgress')
        .doc('${widget.userId}_$lessonId')
        .get();
    return doc.exists && doc.data()?['completed'] == true;
  }

  String _firstName(String name) {
    final parts = name.trim().split(' ');
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : name;
  }

  AppBar _buildAppBar(String title) => AppBar(
        backgroundColor: const Color(0xff003e6d),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(''),
        body: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xff003e6d),
          ),
        ),
      );
    }

    if (_notFound || _user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar('Profile'),
        body: const Center(
          child: Text(
            'User not found',
            style: TextStyle(fontSize: 14, color: Color(0xff888888)),
          ),
        ),
      );
    }

    final user = _user!;
    final rankLabel = _countryRank > 0 ? '#$_countryRank' : '—';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar("${_firstName(user.name)}'s Profile"),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderCard(
                user: user,
                completedCount: _completedCount,
                rankLabel: rankLabel,
              ),
              _MessageButton(userId: widget.userId),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Lessons progress',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0f1923),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (_lessons.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xff003e6d),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    for (var i = 0; i < _lessons.length; i++) ...[
                      if (i > 0) const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _LessonCard(
                          lesson: _lessons[i],
                          isCompleted: _completions[_lessons[i].id] ?? false,
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header Card ──────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.user,
    required this.completedCount,
    required this.rankLabel,
  });

  final AppUser user;
  final int completedCount;
  final String rankLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xff003e6d),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _buildAvatar(),
          const SizedBox(height: 10),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${user.country} · ISP Europe 2026',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          _buildStatsRow(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    if (user.photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: NetworkImage(user.photoUrl),
      );
    }
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xff007398),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 3,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        user.initials,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final divider = Container(
      width: 0.5,
      height: 32,
      color: Colors.white.withValues(alpha: 0.15),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(
          value: '${user.points}',
          label: 'points',
          valueColor: const Color(0xfff9b625),
        ),
        divider,
        _StatItem(value: '$completedCount', label: 'lessons'),
        divider,
        _StatItem(value: rankLabel, label: 'country rank'),
      ],
    );
  }
}

// ─── Stat Item ────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    this.valueColor = Colors.white,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

// ─── Message Button ───────────────────────────────────────────────────────────

class _MessageButton extends StatelessWidget {
  const _MessageButton({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GestureDetector(
        onTap: () => context.push('/chat/direct/$userId'),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffe0ddd6), width: 0.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 18,
                color: Color(0xff003e6d),
              ),
              SizedBox(width: 8),
              Text(
                'Send message',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff003e6d),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Lesson Card ──────────────────────────────────────────────────────────────

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.isCompleted});

  final Lesson lesson;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xfff8f7f4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xff003e6d)
                  : const Color(0xffe0ddd6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCompleted ? Icons.check : Icons.lock_outline,
              color: isCompleted
                  ? const Color(0xfff9b625)
                  : const Color(0xff888888),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.getTitle('en'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0f1923),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isCompleted
                      ? 'Completed · ${lesson.pointsForReading} pts'
                      : 'Not completed',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xff888888),
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
