// users collection already allows read for authenticated users
// No additional rules needed for this feature

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../screens/leaderboard_screen.dart' show getCountryFlag;
import '../services/lesson_service.dart';
import '../services/user_service.dart';

class CountryDetailScreen extends StatefulWidget {
  const CountryDetailScreen({super.key, required this.countryName});
  final String countryName;

  @override
  State<CountryDetailScreen> createState() => _CountryDetailScreenState();
}

class _CountryDetailScreenState extends State<CountryDetailScreen> {
  final _userService = UserService();
  final _db = FirebaseFirestore.instance;
  final _completionFutures = <String, Future<int>>{};
  int _totalLessons = 0;

  @override
  void initState() {
    super.initState();
    LessonService().getLessons().first.then((lessons) {
      if (mounted) setState(() => _totalLessons = lessons.length);
    });
  }

  Future<int> _getCompletionFuture(String userId) {
    return _completionFutures.putIfAbsent(userId, () async {
      final snap = await _db
          .collection('userProgress')
          .where('userId', isEqualTo: userId)
          .get();
      return snap.docs
          .where((doc) => doc.data()['completed'] == true)
          .length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final flag = getCountryFlag(widget.countryName);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff003e6d),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '$flag ${widget.countryName}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: _userService.getAllUsersWithStatus(),
        builder: (_, usersSnap) {
          final allUsers = usersSnap.data ?? [];
          final members = allUsers
              .where((u) => u.country == widget.countryName)
              .toList()
            ..sort((a, b) => b.points.compareTo(a.points));
          final totalPoints = members.fold(0, (acc, u) => acc + u.points);

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _userService.getCountryLeaderboard(),
            builder: (_, lbSnap) {
              final leaderboard = lbSnap.data ?? [];
              int rank = 0;
              final topPoints = leaderboard.isNotEmpty
                  ? leaderboard[0]['points'] as int
                  : 0;
              for (var i = 0; i < leaderboard.length; i++) {
                if (leaderboard[i]['country'] == widget.countryName) {
                  rank = i + 1;
                  break;
                }
              }
              final progress = topPoints > 0
                  ? (totalPoints / topPoints).clamp(0.0, 1.0)
                  : 0.0;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildHeaderCard(
                        flag: flag,
                        totalPoints: totalPoints,
                        memberCount: members.length,
                        rank: rank,
                        progress: progress,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Members',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff0f1923),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (members.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No members from this country yet',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xff888888),
                            ),
                          ),
                        ),
                      )
                    else
                      for (var i = 0; i < members.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () =>
                              context.push('/user/${members[i].uid}'),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: _MemberCard(
                              user: members[i],
                              rank: i + 1,
                              totalLessons: _totalLessons,
                              completionFuture:
                                  _getCompletionFuture(members[i].uid),
                            ),
                          ),
                        ),
                      ],
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard({
    required String flag,
    required int totalPoints,
    required int memberCount,
    required int rank,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xff003e6d),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.countryName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              if (rank > 0)
                Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$totalPoints',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w500,
                  color: Color(0xfff9b625),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'total points',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$memberCount member${memberCount == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (_, constraints) => Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  height: 4,
                  width: constraints.maxWidth * progress,
                  decoration: BoxDecoration(
                    color: const Color(0xfff9b625),
                    borderRadius: BorderRadius.circular(2),
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

// ─── Member Card ──────────────────────────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.user,
    required this.rank,
    required this.totalLessons,
    required this.completionFuture,
  });

  final AppUser user;
  final int rank;
  final int totalLessons;
  final Future<int> completionFuture;

  static const _avatarColors = [
    Color(0xff3eb1c8),
    Color(0xff007398),
    Color(0xffdd7d1b),
    Color(0xff003e6d),
  ];

  Color get _rankColor {
    switch (rank) {
      case 1:
        return const Color(0xfff9b625);
      case 3:
        return const Color(0xffcd7f32);
      default:
        return const Color(0xff888888);
    }
  }

  Widget _buildAvatar(Color color) {
    if (user.photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(user.photoUrl),
      );
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        user.initials,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = user.isCurrentlyOnline;
    final avatarColor = _avatarColors[(rank - 1) % _avatarColors.length];

    return FutureBuilder<int>(
      future: completionFuture,
      builder: (_, snap) {
        final completed = snap.data ?? 0;
        final lessonProgress = totalLessons > 0
            ? (completed / totalLessons).clamp(0.0, 1.0)
            : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xfff8f7f4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _rankColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildAvatar(avatarColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff0f1923),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xff3eb1c8)
                                : const Color(0xffcccccc),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 10,
                            color: isOnline
                                ? const Color(0xff007398)
                                : const Color(0xff888888),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.points} pts',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff007398),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lessons: $completed/$totalLessons',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xff888888),
                      ),
                    ),
                    const SizedBox(height: 4),
                    LayoutBuilder(
                      builder: (_, constraints) => Stack(
                        children: [
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color(0xffe0ddd6),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            height: 3,
                            width: constraints.maxWidth * lessonProgress,
                            decoration: BoxDecoration(
                              color: const Color(0xff003e6d),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
