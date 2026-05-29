// Firestore index needed:
// Collection: users, Field: lastSeen (Ascending)
// Create at: Firebase Console → Firestore → Indexes

import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

class LiveMapScreen extends StatelessWidget {
  const LiveMapScreen({super.key});

  static const _positions = [
    (60.0, 50.0),
    (240.0, 90.0),
    (110.0, 130.0),
    (180.0, 160.0),
    (80.0, 170.0),
    (260.0, 50.0),
    (150.0, 80.0),
    (200.0, 140.0),
  ];

  String _firstName(AppUser user) {
    final parts = user.name.trim().split(' ');
    return parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : '?';
  }

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
                _buildHeader(userService),
                const SizedBox(height: 14),
                _buildMapArea(userService),
                _buildAttendeesSection(userService),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserService userService) {
    return StreamBuilder<List<AppUser>>(
      stream: userService.getOnlineUsers(),
      builder: (_, snap) {
        final count = snap.data?.length ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live now',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff0f1923),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'ISP Europe Conference · Poland',
                  style: TextStyle(fontSize: 12, color: Color(0xff888888)),
                ),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xffe8f8f5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xff3eb1c8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$count online',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff007398),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapArea(UserService userService) {
    return StreamBuilder<List<AppUser>>(
      stream: userService.getAllUsersWithStatus(),
      builder: (_, snap) {
        final users = snap.data ?? [];
        return Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: const Color(0xffeaf2f8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffd4e6f1), width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.language,
                    size: 120,
                    color: const Color(0xff003e6d).withValues(alpha: 0.15),
                  ),
                ),
                for (var i = 0; i < users.length; i++)
                  _buildUserDot(users[i], i),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xff3eb1c8),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Online',
                        style: TextStyle(
                            fontSize: 9, color: Color(0xff555555)),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xffcccccc),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Offline',
                        style: TextStyle(
                            fontSize: 9, color: Color(0xff555555)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserDot(AppUser user, int index) {
    final pos = _positions[index % _positions.length];
    final firstName = _firstName(user);
    final isOnline = user.isCurrentlyOnline;

    return Positioned(
      left: pos.$1,
      top: pos.$2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border:
                  Border.all(color: const Color(0xffe0ddd6), width: 0.5),
            ),
            child: Text(
              firstName,
              style: const TextStyle(fontSize: 9),
            ),
          ),
          const SizedBox(height: 3),
          if (isOnline)
            _PulsingDot()
          else
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xffcccccc),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendeesSection(UserService userService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All attendees',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xff0f1923),
          ),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<AppUser>>(
          stream: userService.getAllUsersWithStatus(),
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xff003e6d),
                  ),
                ),
              );
            }
            final users = snap.data ?? [];
            return Column(
              children: [
                for (var i = 0; i < users.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _UserCard(user: users[i], index: i),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xff3eb1c8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.index});

  final AppUser user;
  final int index;

  static const _avatarColors = [
    Color(0xff3eb1c8),
    Color(0xff007398),
    Color(0xffdd7d1b),
    Color(0xff003e6d),
    Color(0xfff9b625),
  ];

  void _showProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _UserProfileSheet(
        user: user,
        color: _avatarColors[index % _avatarColors.length],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = user.isCurrentlyOnline;
    final color = _avatarColors[index % _avatarColors.length];

    return GestureDetector(
      onTap: () => _showProfile(context),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xfff8f7f4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                user.initials,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff0f1923),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${user.country} · ${user.points} pts',
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xff888888)),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                const SizedBox(width: 4),
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
          ],
        ),
      ),
    );
  }
}

class _UserProfileSheet extends StatelessWidget {
  const _UserProfileSheet({required this.user, required this.color});

  final AppUser user;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xffe0ddd6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              user.initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xff0f1923),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.country,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xff888888)),
              ),
              const Text(
                ' · ',
                style:
                    TextStyle(fontSize: 13, color: Color(0xff888888)),
              ),
              Text(
                '${user.points} pts',
                style: const TextStyle(
                    fontSize: 13, color: Color(0xff888888)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xfff8f7f4),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Close',
                style: TextStyle(fontSize: 14, color: Color(0xff0f1923)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
