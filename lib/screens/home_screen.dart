// Firestore rules needed (update in Firebase Console):
// match /users/{uid} {
//   allow read: if request.auth != null;
//   allow write: if request.auth != null && request.auth.uid == uid;
// }
// Index needed: Collection 'users', Field: lastSeen (Ascending)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../models/lesson.dart';
import '../providers/navigation_provider.dart';
import '../services/lesson_service.dart';
import '../services/user_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _lessonService = LessonService();
  final _userService = UserService();
  StreamSubscription<List<Lesson>>? _sub;

  List<Lesson> _lessons = [];
  Map<String, bool> _completions = {};
  Map<String, double> _progress = {};
  bool _lessonsLoading = true;

  @override
  void initState() {
    super.initState();
    _sub = _lessonService.getLessons().listen((lessons) {
      if (mounted) {
        setState(() {
          _lessons = lessons;
          _lessonsLoading = false;
        });
      }
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
    final completionFutures =
        lessons.map((l) => _lessonService.isLessonCompleted(l.id));
    final progressFutures =
        lessons.map((l) => _lessonService.getLessonProgress(l.id));
    final completions = await Future.wait(completionFutures);
    final progressMaps = await Future.wait(progressFutures);
    if (!mounted) return;
    setState(() {
      _completions =
          Map.fromIterables(lessons.map((l) => l.id), completions);
      _progress = Map.fromIterables(
        lessons.map((l) => l.id),
        progressMaps.map((m) => (m['progress'] as double?) ?? 0.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                StreamBuilder<AppUser?>(
                  stream: _userService.getCurrentUser(),
                  builder: (_, snap) => _Header(user: snap.data),
                ),
                const SizedBox(height: 16),
                _TodayLessonCard(
                  lessons: _lessons,
                  completions: _completions,
                  progress: _progress,
                  loading: _lessonsLoading,
                ),
                _StatsRow(userService: _userService),
                _OnlineNowRow(userService: _userService),
                _AllLessonsSection(
                  lessons: _lessons.take(3).toList(),
                  completions: _completions,
                  progress: _progress,
                  loading: _lessonsLoading,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final AppUser? user;

  String get _firstName {
    final name = user?.name ?? '';
    if (name.isEmpty) return 'Friend';
    return name.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good morning',
              style: TextStyle(fontSize: 11, color: Color(0xff888888)),
            ),
            const SizedBox(height: 2),
            Text(
              _firstName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xff0f1923),
              ),
            ),
          ],
        ),
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xff003e6d),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            user?.initials ?? '?',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Today's Lesson Card ──────────────────────────────────────────────────────

class _TodayLessonCard extends StatelessWidget {
  const _TodayLessonCard({
    required this.lessons,
    required this.completions,
    required this.progress,
    required this.loading,
  });

  final List<Lesson> lessons;
  final Map<String, bool> completions;
  final Map<String, double> progress;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        height: 150,
        decoration: BoxDecoration(
          color: const Color(0xff003e6d).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xff003e6d),
            ),
          ),
        ),
      );
    }

    if (lessons.isEmpty) return const SizedBox.shrink();

    final completedCount = completions.values.where((v) => v).length;
    final total = lessons.length;

    Lesson? current;
    for (final l in lessons) {
      if (completions[l.id] != true) {
        current = l;
        break;
      }
    }

    if (current == null) {
      return _buildCelebration();
    }

    final hasProgress = (progress[current.id] ?? 0.0) > 0;
    final sectionCount = current.sections.length;

    return GestureDetector(
      onTap: () => context.go('/lesson/${current!.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xff003e6d),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                bottom: -30,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: -50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(total, (i) {
                        return Expanded(
                          child: Container(
                            margin:
                                EdgeInsets.only(right: i < total - 1 ? 4 : 0),
                            height: 3,
                            decoration: BoxDecoration(
                              color: i < completedCount
                                  ? const Color(0xfff9b625)
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'DAY ${current.dayNumber} OF $total',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      current.getTitle('en'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sectionCount sections · ${current.totalQuestions} questions',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xfff9b625),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        hasProgress ? 'Continue reading' : 'Start reading',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff3d2800),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelebration() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xff003e6d),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "You've completed all lessons! 🎉",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xfff9b625),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Amazing work this week.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.userService});
  final UserService userService;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: StreamBuilder<AppUser?>(
        stream: userService.getCurrentUser(),
        builder: (_, userSnap) {
          final user = userSnap.data;
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: userService.getCountryLeaderboard(),
            builder: (_, lbSnap) {
              final leaderboard = lbSnap.data ?? [];
              final country = user?.country ?? '';

              int rank = 0;
              int countryPts = 0;
              int ptsAbove = 0;

              for (var i = 0; i < leaderboard.length; i++) {
                if (leaderboard[i]['country'] == country) {
                  rank = i + 1;
                  countryPts = leaderboard[i]['points'] as int;
                  if (i > 0) {
                    ptsAbove =
                        (leaderboard[i - 1]['points'] as int) - countryPts;
                  }
                  break;
                }
              }

              final points = user?.points ?? 0;
              final pointsSub =
                  points > 0 ? '+$points total' : 'Start reading!';
              final pointsSubColor = points > 0
                  ? const Color(0xff007398)
                  : const Color(0xff888888);

              final rankValue = rank > 0 ? '#$rank' : '—';
              final String rankSub;
              final Color rankSubColor;
              if (rank == 0) {
                rankSub = '—';
                rankSubColor = const Color(0xff888888);
              } else if (rank == 1) {
                rankSub = 'Leading!';
                rankSubColor = const Color(0xff007398);
              } else {
                rankSub = '$ptsAbove pts behind';
                rankSubColor = const Color(0xffdd7d1b);
              }

              return Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Your points',
                      value: '$points',
                      sub: pointsSub,
                      subColor: pointsSubColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: 'Country rank',
                      value: rankValue,
                      sub: rankSub,
                      subColor: rankSubColor,
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.subColor,
  });

  final String label;
  final String value;
  final String sub;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: const Color(0xfff8f7f4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 10, color: Color(0xff888888))),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Color(0xff0f1923),
              )),
          const SizedBox(height: 2),
          Text(sub, style: TextStyle(fontSize: 10, color: subColor)),
        ],
      ),
    );
  }
}

// ─── Online Now Row ───────────────────────────────────────────────────────────

class _OnlineNowRow extends ConsumerWidget {
  const _OnlineNowRow({required this.userService});
  final UserService userService;

  static const _avatarColors = [
    Color(0xff3eb1c8),
    Color(0xff007398),
    Color(0xffdd7d1b),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: StreamBuilder<List<AppUser>>(
        stream: userService.getOnlineUsers(),
        builder: (_, snap) {
          final users = snap.data ?? [];
          final count = users.length;
          final shown = users.take(3).toList();
          final remaining = count - shown.length;

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Online now',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff0f1923),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        ref.read(navigationProvider.notifier).setIndex(2),
                    child: const Text(
                      'See all',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xff007398)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (count == 0)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'No one online right now',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xff888888)),
                  ),
                )
              else
                Row(
                  children: [
                    _AvatarStack(
                      users: shown,
                      remaining: remaining,
                      colors: _avatarColors,
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xff3eb1c8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$count online',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xff888888)),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({
    required this.users,
    required this.remaining,
    required this.colors,
  });

  final List<AppUser> users;
  final int remaining;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final totalCircles = users.length + (remaining > 0 ? 1 : 0);
    final width = totalCircles <= 1
        ? 30.0
        : 30.0 + (totalCircles - 1) * 22.0;

    return SizedBox(
      width: width,
      height: 30,
      child: Stack(
        children: [
          for (var i = 0; i < users.length; i++)
            Positioned(
              left: i * 22.0,
              child: _CircleAvatar(
                color: colors[i % colors.length],
                label: users[i].initials,
                textColor: Colors.white,
                fontSize: 9,
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: users.length * 22.0,
              child: _CircleAvatar(
                color: const Color(0xfff8f7f4),
                label: '+$remaining',
                textColor: const Color(0xff888888),
                fontSize: 8,
              ),
            ),
        ],
      ),
    );
  }
}

class _CircleAvatar extends StatelessWidget {
  const _CircleAvatar({
    required this.color,
    required this.label,
    required this.textColor,
    required this.fontSize,
  });

  final Color color;
  final String label;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ─── All Lessons Section ──────────────────────────────────────────────────────

class _AllLessonsSection extends StatelessWidget {
  const _AllLessonsSection({
    required this.lessons,
    required this.completions,
    required this.progress,
    required this.loading,
  });

  final List<Lesson> lessons;
  final Map<String, bool> completions;
  final Map<String, double> progress;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading || lessons.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All lessons',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xff0f1923),
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < lessons.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          _LessonRow(
            lesson: lessons[i],
            isCompleted: completions[lessons[i].id] ?? false,
            readProgress: progress[lessons[i].id] ?? 0.0,
          ),
        ],
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.isCompleted,
    required this.readProgress,
  });

  final Lesson lesson;
  final bool isCompleted;
  final double readProgress;

  @override
  Widget build(BuildContext context) {
    final isActive = !isCompleted && readProgress > 0;

    final Color iconBoxColor;
    final Color iconColor;
    final IconData iconData;
    final Color subColor;
    final Color chevronColor;
    final String subText;

    if (isCompleted) {
      iconBoxColor = const Color(0xff003e6d);
      iconColor = const Color(0xfff9b625);
      iconData = Icons.check;
      subColor = const Color(0xff888888);
      chevronColor = const Color(0xffbbbbbb);
      subText = 'Completed · ${lesson.pointsForReading} pts earned';
    } else if (isActive) {
      iconBoxColor = const Color(0xff003e6d);
      iconColor = Colors.white;
      iconData = Icons.menu_book_rounded;
      subColor = const Color(0xff007398);
      chevronColor = const Color(0xff003e6d);
      subText = 'In progress · ${(readProgress * 100).round()}% done';
    } else {
      iconBoxColor = const Color(0xff003e6d);
      iconColor = Colors.white;
      iconData = Icons.menu_book_rounded;
      subColor = const Color(0xff888888);
      chevronColor = const Color(0xffbbbbbb);
      subText =
          '${lesson.sections.length} sections · ${lesson.totalQuestions} questions';
    }

    return GestureDetector(
      onTap: () => context.go('/lesson/${lesson.id}'),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xfff0f5ff)
              : const Color(0xfff8f7f4),
          borderRadius: BorderRadius.circular(10),
          border: isActive
              ? Border.all(
                  color: const Color(0xff003e6d), width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBoxColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: iconColor, size: 16),
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
                  Text(subText,
                      style:
                          TextStyle(fontSize: 10, color: subColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: chevronColor, size: 18),
          ],
        ),
      ),
    );
  }
}
