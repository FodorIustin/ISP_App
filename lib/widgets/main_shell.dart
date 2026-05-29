import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../screens/home_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/lessons_screen.dart';
import '../screens/live_map_screen.dart';
import '../screens/profile_screen.dart';
import '../services/presence_service.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  final _presence = PresenceService();

  static const _screens = [
    HomeScreen(),
    LessonsScreen(),
    LiveMapScreen(),
    LeaderboardScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _presence.setOnline();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presence.setOffline();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _presence.setOnline();
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        _presence.setOffline();
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = ref.watch(navigationProvider);
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0xffeeeeee), width: 0.5),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: IndexedStack(index: index, children: _screens),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xffeeeeee), width: 0.5),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => ref.read(navigationProvider.notifier).setIndex(i),
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xff003e6d),
            unselectedItemColor: const Color(0xffbbbbbb),
            selectedFontSize: 9,
            unselectedFontSize: 9,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: 'Lessons',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined),
                activeIcon: Icon(Icons.location_on),
                label: 'Live',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events),
                label: 'Rankings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
