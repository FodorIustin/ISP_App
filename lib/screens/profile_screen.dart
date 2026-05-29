import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/lesson.dart';
import '../screens/leaderboard_screen.dart' show getCountryFlag;
import '../services/auth_service.dart';
import '../services/lesson_service.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _lessonService = LessonService();
  StreamSubscription<List<Lesson>>? _lessonSub;

  List<Lesson> _lessons = [];
  Map<String, bool> _completions = {};
  String _language = '';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _lessonSub = _lessonService.getLessons().listen((lessons) async {
      if (!mounted) return;
      setState(() => _lessons = lessons);
      final completions = await Future.wait(
        lessons.map((l) => _lessonService.isLessonCompleted(l.id)),
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

  @override
  void dispose() {
    _lessonSub?.cancel();
    super.dispose();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _language = prefs.getString('selected_language') ?? 'English',
      );
    }
  }

  void _showEditProfile(AppUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _completions.values.where((v) => v).length;
    final total = _lessons.length;

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
                _HeaderCard(
                  userService: _userService,
                  completedCount: completedCount,
                  total: total,
                  onEditProfile: _showEditProfile,
                ),
                const Text(
                  'My progress',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0f1923),
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
                        _LessonProgressCard(
                          lesson: _lessons[i],
                          isCompleted: _completions[_lessons[i].id] ?? false,
                        ),
                      ],
                    ],
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0f1923),
                  ),
                ),
                const SizedBox(height: 10),
                _AccountSection(
                  language: _language,
                  userService: _userService,
                  onEditProfile: _showEditProfile,
                  onLanguageTap: () async {
                    await context.push('/change-language');
                    _loadLanguage();
                  },
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

// ─── Header Card ──────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.userService,
    required this.completedCount,
    required this.total,
    required this.onEditProfile,
  });

  final UserService userService;
  final int completedCount;
  final int total;
  final void Function(AppUser) onEditProfile;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: userService.getCurrentUser(),
      builder: (_, userSnap) {
        final user = userSnap.data;
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: userService.getCountryLeaderboard(),
          builder: (_, lbSnap) {
            final leaderboard = lbSnap.data ?? [];

            int rank = 0;
            if (user != null) {
              for (var i = 0; i < leaderboard.length; i++) {
                if (leaderboard[i]['country'] == user.country) {
                  rank = i + 1;
                  break;
                }
              }
            }

            final points = user?.points ?? 0;
            final lessonsLabel = '$completedCount/$total';
            final rankLabel = rank > 0 ? '#$rank' : '—';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                color: const Color(0xff003e6d),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildAvatar(user),
                  const SizedBox(height: 10),
                  Text(
                    user?.name ?? '',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user?.country ?? ''} · ISP Europe 2026',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildStatsRow(
                    points: points,
                    lessonsLabel: lessonsLabel,
                    rankLabel: rankLabel,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvatar(AppUser? user) {
    if (user != null && user.photoUrl.isNotEmpty) {
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
        user?.initials ?? '?',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatsRow({
    required int points,
    required String lessonsLabel,
    required String rankLabel,
  }) {
    final divider = Container(
      width: 0.5,
      height: 32,
      color: Colors.white.withValues(alpha: 0.15),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(
          value: '$points',
          label: 'points',
          valueColor: const Color(0xfff9b625),
        ),
        divider,
        _StatItem(value: lessonsLabel, label: 'lessons'),
        divider,
        _StatItem(value: rankLabel, label: 'country rank'),
      ],
    );
  }
}

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
            fontSize: 18,
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

// ─── Lesson Progress Card ─────────────────────────────────────────────────────

class _LessonProgressCard extends StatelessWidget {
  const _LessonProgressCard({
    required this.lesson,
    required this.isCompleted,
  });

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
              color: isCompleted ? const Color(0xfff9b625) : const Color(0xff888888),
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
                      ? 'Completed · ${lesson.pointsForReading} pts earned'
                      : 'Not completed',
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xff888888)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Account Section ──────────────────────────────────────────────────────────

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.language,
    required this.userService,
    required this.onEditProfile,
    required this.onLanguageTap,
  });

  final String language;
  final UserService userService;
  final void Function(AppUser) onEditProfile;
  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: userService.getCurrentUser(),
      builder: (_, snap) {
        final user = snap.data;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffeeeeee), width: 0.5),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              _AccountRow(
                icon: Icons.person_outline,
                label: 'Edit profile',
                onTap: user != null ? () => onEditProfile(user) : null,
              ),
              const Divider(height: 0.5, thickness: 0.5, color: Color(0xffeeeeee)),
              _AccountRow(
                icon: Icons.language,
                label: 'Language',
                trailing: language,
                onTap: onLanguageTap,
              ),
              const Divider(height: 0.5, thickness: 0.5, color: Color(0xffeeeeee)),
              _AccountRow(
                icon: Icons.logout,
                label: 'Sign out',
                iconColor: const Color(0xffE24B4A),
                labelColor: const Color(0xffE24B4A),
                onTap: () async {
                  await AuthService().signOut();
                  if (context.mounted) context.go('/language');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.icon,
    required this.label,
    this.trailing,
    this.iconColor = const Color(0xff888888),
    this.labelColor = const Color(0xff0f1923),
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: labelColor),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xff888888)),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: const Color(0xffbbbbbb),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Edit Profile Bottom Sheet ────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  const _EditProfileSheet({required this.user});
  final AppUser user;

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameController;
  late String _country;
  bool _saving = false;

  static const _countries = [
    'Albania', 'Armenia', 'Austria', 'Belgium', 'Bulgaria',
    'Czech Republic', 'Greece', 'Hungary', 'Moldova', 'Netherlands',
    'North Macedonia', 'Poland', 'Portugal', 'Romania', 'Spain',
    'Ukraine', 'Russia',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _country = _countries.contains(widget.user.country)
        ? widget.user.country
        : _countries.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await UserService().updateProfile(
      name: _nameController.text.trim(),
      country: _country,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xffe0ddd6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Edit profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xff0f1923),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _country,
              decoration: const InputDecoration(
                labelText: 'Country',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: _countries
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Text(
                            getCountryFlag(c),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(c),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _country = v);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: _saving ? null : _save,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: _saving
                        ? const Color(0xff003e6d).withValues(alpha: 0.6)
                        : const Color(0xff003e6d),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save changes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
