// Firestore index needed:
// Collection: users, Field: lastSeen (Ascending)
// Create at: Firebase Console → Firestore → Indexes

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/app_user.dart';
import '../services/user_service.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  String _filter = 'all';

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

  List<AppUser> _applyFilter(List<AppUser> all) {
    switch (_filter) {
      case 'online':
        return all.where((u) => u.isCurrentlyOnline).toList();
      case 'offline':
        return all.where((u) => !u.isCurrentlyOnline).toList();
      default:
        return all;
    }
  }

  String _emptyMessage() {
    switch (_filter) {
      case 'online':
        return 'No users online right now';
      case 'offline':
        return 'No offline users';
      default:
        return 'No attendees yet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = UserService();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<List<AppUser>>(
          stream: userService.getAllUsersWithStatus(),
          builder: (_, snap) {
            final allUsers = snap.data ?? [];
            final onlineCount =
                allUsers.where((u) => u.isCurrentlyOnline).length;
            final offlineCount = allUsers.length - onlineCount;
            final filteredUsers = _applyFilter(allUsers);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildHeader(onlineCount),
                    const SizedBox(height: 14),
                    _buildMapArea(context, filteredUsers),
                    _buildAttendeesSection(
                      filteredUsers: filteredUsers,
                      allCount: allUsers.length,
                      onlineCount: onlineCount,
                      offlineCount: offlineCount,
                      isLoading: snap.connectionState ==
                          ConnectionState.waiting,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int onlineCount) {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                '$onlineCount online',
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
  }

  Widget _buildMapArea(BuildContext context, List<AppUser> filteredUsers) {
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
            for (var i = 0; i < filteredUsers.length; i++)
              _buildUserDot(context, filteredUsers[i], i),
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
                    style:
                        TextStyle(fontSize: 9, color: Color(0xff555555)),
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
                    style:
                        TextStyle(fontSize: 9, color: Color(0xff555555)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserSheet(BuildContext context, AppUser user, int index) {
    const avatarColors = [
      Color(0xff3eb1c8),
      Color(0xff007398),
      Color(0xffdd7d1b),
      Color(0xff003e6d),
      Color(0xfff9b625),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _UserProfileSheet(
        user: user,
        color: avatarColors[index % avatarColors.length],
      ),
    );
  }

  Widget _buildUserDot(BuildContext context, AppUser user, int index) {
    final pos = _positions[index % _positions.length];
    final firstName = _firstName(user);
    final isOnline = user.isCurrentlyOnline;

    return Positioned(
      left: pos.$1,
      top: pos.$2,
      child: GestureDetector(
        onTap: () => _showUserSheet(context, user, index),
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
      ),
    );
  }

  Widget _buildAttendeesSection({
    required List<AppUser> filteredUsers,
    required int allCount,
    required int onlineCount,
    required int offlineCount,
    required bool isLoading,
  }) {
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
        // Filter chips
        Row(
          children: [
            _FilterChip(
              label: 'All',
              count: allCount,
              selected: _filter == 'all',
              onTap: () => setState(() => _filter = 'all'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Online',
              count: onlineCount,
              selected: _filter == 'online',
              onTap: () => setState(() => _filter = 'online'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Offline',
              count: offlineCount,
              selected: _filter == 'offline',
              onTap: () => setState(() => _filter = 'offline'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xff003e6d),
              ),
            ),
          )
        else if (filteredUsers.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                _emptyMessage(),
                style: const TextStyle(
                    fontSize: 13, color: Color(0xff888888)),
              ),
            ),
          )
        else
          Column(
            children: [
              for (var i = 0; i < filteredUsers.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                _UserCard(user: filteredUsers[i], index: i),
              ],
            ],
          ),
      ],
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xff003e6d)
              : const Color(0xfff8f7f4),
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? null
              : Border.all(
                  color: const Color(0xffe0ddd6), width: 0.5),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : const Color(0xff888888),
          ),
        ),
      ),
    );
  }
}

// ─── Pulsing Dot ─────────────────────────────────────────────────────────────

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

// ─── User Card ────────────────────────────────────────────────────────────────

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

  @override
  Widget build(BuildContext context) {
    final isOnline = user.isCurrentlyOnline;
    final color = _avatarColors[index % _avatarColors.length];

    return GestureDetector(
      onTap: () => context.push('/user/${user.uid}'),
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

// ─── User Profile Sheet ───────────────────────────────────────────────────────

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
                style: TextStyle(fontSize: 13, color: Color(0xff888888)),
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
            onTap: () {
              final router = GoRouter.of(context);
              router.pop();
              router.push('/user/${user.uid}');
            },
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xff003e6d),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text(
                'View profile',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
                style:
                    TextStyle(fontSize: 14, color: Color(0xff0f1923)),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
