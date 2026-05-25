import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;

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
      bottomNavigationBar: _BottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
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
        Row(
          children: [
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
            IconButton(
              icon: const Icon(
                Icons.logout,
                color: Color(0xff888888),
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () async {
                await AuthService().signOut();
                if (context.mounted) context.go('/language');
              },
            ),
          ],
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

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const active = Color(0xff003e6d);
    const inactive = Color(0xffbbbbbb);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xffeeeeee), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Row(
            children: [
              _NavTab(
                icon: Icons.home,
                label: 'Home',
                active: currentIndex == 0,
                activeColor: active,
                inactiveColor: inactive,
                onTap: () => onTap(0),
              ),
              _NavTab(
                icon: Icons.menu_book_outlined,
                label: 'Lessons',
                active: currentIndex == 1,
                activeColor: active,
                inactiveColor: inactive,
                onTap: () => onTap(1),
              ),
              _NavTab(
                icon: Icons.location_pin,
                label: 'Live',
                active: currentIndex == 2,
                activeColor: active,
                inactiveColor: inactive,
                onTap: () => onTap(2),
              ),
              _NavTab(
                icon: Icons.emoji_events_outlined,
                label: 'Rankings',
                active: currentIndex == 3,
                activeColor: active,
                inactiveColor: inactive,
                onTap: () => onTap(3),
              ),
              _NavTab(
                icon: Icons.person_outline,
                label: 'Profile',
                active: currentIndex == 4,
                activeColor: active,
                inactiveColor: inactive,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : inactiveColor;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(fontSize: 9, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
