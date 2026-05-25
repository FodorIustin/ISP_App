import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String get _displayName =>
      FirebaseAuth.instance.currentUser?.displayName ?? 'Friend';

  String get _firstName => _displayName.split(' ').first;

  String get _initials {
    final parts = _displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _displayName.isNotEmpty
        ? _displayName[0].toUpperCase()
        : '?';
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
                _Header(firstName: _firstName, initials: _initials),
                const SizedBox(height: 16),
                const _TodayLessonCard(),
                const _StatsRow(),
                const _OnlineNowRow(),
                const _AllLessonsSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.firstName, required this.initials});
  final String firstName;
  final String initials;

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
              style: TextStyle(
                fontSize: 11,
                color: Color(0xff888888),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              firstName,
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
            initials,
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

// ─── Today's Lesson Card ─────────────────────────────────────────────────────

class _TodayLessonCard extends StatelessWidget {
  const _TodayLessonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xff003e6d),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Subtle circle decoration
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
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Progress segments
                  Row(
                    children: List.generate(5, (i) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                          height: 3,
                          decoration: BoxDecoration(
                            color: i < 2
                                ? const Color(0xfff9b625)
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  // Day label
                  Text(
                    'DAY 2 OF 5',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Lesson title
                  const Text(
                    'The power of community in education',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    '8 min read · 3 questions',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Continue button
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xfff9b625),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Continue reading',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff3d2800),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

// ─── Stats Row ───────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Your points',
              value: '245',
              sub: '+20 today',
              subColor: const Color(0xff007398),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Romania rank',
              value: '#2',
              sub: '18 pts behind',
              subColor: const Color(0xffdd7d1b),
            ),
          ),
        ],
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
          Text(sub,
              style: TextStyle(fontSize: 10, color: subColor)),
        ],
      ),
    );
  }
}

// ─── Online Now ───────────────────────────────────────────────────────────────

class _OnlineNowRow extends StatelessWidget {
  const _OnlineNowRow();

  static const _avatars = [
    (Color(0xff3eb1c8), 'AK'),
    (Color(0xff007398), 'ML'),
    (Color(0xffdd7d1b), 'PV'),
    (Color(0xfff8f7f4), '+41'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          // Title row
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
                onTap: () {},
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xff007398),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Avatars + online count
          Row(
            children: [
              // Overlapping avatars
              SizedBox(
                width: 30.0 + 3 * 22.0, // 4 avatars with -8px overlap
                height: 30,
                child: Stack(
                  children: List.generate(_avatars.length, (i) {
                    final (color, label) = _avatars[i];
                    final isLast = i == _avatars.length - 1;
                    return Positioned(
                      left: i * 22.0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: isLast ? 8 : 9,
                            fontWeight: FontWeight.w600,
                            color: isLast
                                ? const Color(0xff888888)
                                : Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 10),
              // Green dot
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xff3eb1c8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              const Text(
                '44 online',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xff888888),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── All Lessons ──────────────────────────────────────────────────────────────

class _AllLessonsSection extends StatelessWidget {
  const _AllLessonsSection();

  @override
  Widget build(BuildContext context) {
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
        const _LessonRow(
          status: _LessonStatus.completed,
          title: 'Lesson 1 — Introduction',
          sub: 'Completed · 30pts earned',
        ),
        const SizedBox(height: 8),
        const _LessonRow(
          status: _LessonStatus.active,
          title: 'Lesson 2 — Community',
          sub: 'In progress · 8 min left',
        ),
        const SizedBox(height: 8),
        const _LessonRow(
          status: _LessonStatus.locked,
          title: 'Lesson 3 — Faith & Teaching',
          sub: 'Unlocks May 21',
        ),
      ],
    );
  }
}

enum _LessonStatus { completed, active, locked }

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.status,
    required this.title,
    required this.sub,
  });

  final _LessonStatus status;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final isActive = status == _LessonStatus.active;
    final isLocked = status == _LessonStatus.locked;
    final isCompleted = status == _LessonStatus.completed;

    Color iconBoxColor;
    Color iconColor;
    IconData iconData;
    Color subColor;
    Color chevronColor;

    if (isCompleted) {
      iconBoxColor = const Color(0xff003e6d);
      iconColor = const Color(0xfff9b625);
      iconData = Icons.check;
      subColor = const Color(0xff888888);
      chevronColor = const Color(0xffbbbbbb);
    } else if (isActive) {
      iconBoxColor = const Color(0xff003e6d);
      iconColor = Colors.white;
      iconData = Icons.menu_book_rounded;
      subColor = const Color(0xff007398);
      chevronColor = const Color(0xff003e6d);
    } else {
      iconBoxColor = const Color(0xffcccccc);
      iconColor = Colors.white;
      iconData = Icons.lock_outline;
      subColor = const Color(0xff888888);
      chevronColor = const Color(0xffbbbbbb);
    }

    Widget card = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xfff0f5ff) : const Color(0xfff8f7f4),
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border.all(color: const Color(0xff003e6d), width: 1.5)
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
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0f1923),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(fontSize: 10, color: subColor),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: chevronColor, size: 18),
        ],
      ),
    );

    if (isLocked) {
      card = Opacity(opacity: 0.5, child: card);
    }

    return card;
  }
}
