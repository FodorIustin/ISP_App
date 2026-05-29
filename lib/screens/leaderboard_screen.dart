import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

String getCountryFlag(String country) {
  switch (country) {
    case 'Albania':
      return '🇦🇱';
    case 'Armenia':
      return '🇦🇲';
    case 'Austria':
      return '🇦🇹';
    case 'Belgium':
      return '🇧🇪';
    case 'Bulgaria':
      return '🇧🇬';
    case 'Czech Republic':
      return '🇨🇿';
    case 'Greece':
      return '🇬🇷';
    case 'Hungary':
      return '🇭🇺';
    case 'Moldova':
      return '🇲🇩';
    case 'Netherlands':
      return '🇳🇱';
    case 'North Macedonia':
      return '🇲🇰';
    case 'Poland':
      return '🇵🇱';
    case 'Portugal':
      return '🇵🇹';
    case 'Romania':
      return '🇷🇴';
    case 'Spain':
      return '🇪🇸';
    case 'Ukraine':
      return '🇺🇦';
    case 'Russia':
      return '🇷🇺';
    default:
      return '🌍';
  }
}

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
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
                const Text(
                  'Rankings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0f1923),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Updated live · ISP Europe 2026',
                  style: TextStyle(fontSize: 12, color: Color(0xff888888)),
                ),
                const SizedBox(height: 16),
                _YourCountryCard(userService: userService),
                const Text(
                  'All countries',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0f1923),
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: userService.getCountryLeaderboard(),
                  builder: (_, snap) {
                    final leaderboard = snap.data ?? [];
                    if (leaderboard.isEmpty) return const SizedBox.shrink();
                    final topPoints = leaderboard[0]['points'] as int;
                    return Column(
                      children: [
                        for (var i = 0; i < leaderboard.length; i++) ...[
                          if (i > 0) const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => context.push(
                              '/country/${Uri.encodeComponent(leaderboard[i]['country'] as String)}',
                            ),
                            child: _CountryCard(
                              rank: i + 1,
                              country: leaderboard[i]['country'] as String,
                              points: leaderboard[i]['points'] as int,
                              members: leaderboard[i]['members'] as int,
                              topPoints: topPoints,
                            ),
                          ),
                        ],
                      ],
                    );
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

class _YourCountryCard extends StatelessWidget {
  const _YourCountryCard({required this.userService});
  final UserService userService;

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
            if (user == null || leaderboard.isEmpty) {
              return const SizedBox.shrink();
            }

            int rank = 0;
            int yourPoints = 0;
            int members = 0;
            for (var i = 0; i < leaderboard.length; i++) {
              if (leaderboard[i]['country'] == user.country) {
                rank = i + 1;
                yourPoints = leaderboard[i]['points'] as int;
                members = leaderboard[i]['members'] as int;
                break;
              }
            }
            if (rank == 0) return const SizedBox.shrink();

            final topPoints = leaderboard[0]['points'] as int;
            final progress =
                topPoints > 0 ? (yourPoints / topPoints).clamp(0.0, 1.0) : 0.0;

            final String footerText;
            if (rank == 1) {
              footerText = 'Leading the pack!';
            } else {
              final diff =
                  (leaderboard[rank - 2]['points'] as int) - yourPoints;
              footerText = '$diff pts behind #${rank - 1}';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: const Color(0xff003e6d),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your country',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        getCountryFlag(user.country),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.country,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '$members member${members == 1 ? '' : 's'} active',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '$yourPoints',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w500,
                              color: Color(0xfff9b625),
                            ),
                          ),
                          Text(
                            'pts · #$rank',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ],
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
                  const SizedBox(height: 6),
                  Text(
                    footerText,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.rank,
    required this.country,
    required this.points,
    required this.members,
    required this.topPoints,
  });

  final int rank;
  final String country;
  final int points;
  final int members;
  final int topPoints;

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    final progress =
        topPoints > 0 ? (points / topPoints).clamp(0.0, 1.0) : 0.0;
    final flag = getCountryFlag(country);
    final membersLabel = '$members member${members == 1 ? '' : 's'} · $points pts';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isFirst ? const Color(0xfffbf9f0) : const Color(0xfff8f7f4),
        borderRadius: BorderRadius.circular(12),
        border: isFirst
            ? Border.all(color: const Color(0xfff0e4b0), width: 0.5)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isFirst
                    ? const Color(0xffc8960a)
                    : const Color(0xff888888),
              ),
            ),
          ),
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  country,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0f1923),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  membersLabel,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xff888888)),
                ),
                const SizedBox(height: 4),
                LayoutBuilder(
                  builder: (_, constraints) => Stack(
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: isFirst
                              ? const Color(0xfff0e8cc)
                              : const Color(0xffe8e6e0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        height: 3,
                        width: constraints.maxWidth *
                            (isFirst ? 1.0 : progress),
                        decoration: BoxDecoration(
                          color: isFirst
                              ? const Color(0xfff9b625)
                              : const Color(0xff007398),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$points',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xff0f1923),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right,
            size: 16,
            color: Color(0xffbbbbbb),
          ),
        ],
      ),
    );
  }
}
