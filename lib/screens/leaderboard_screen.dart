import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff003e6d),
        title: const Text('Rankings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 64, color: Color(0xffe0ddd6)),
            SizedBox(height: 12),
            Text('Rankings coming soon',
                style: TextStyle(fontSize: 14, color: Color(0xff888888))),
          ],
        ),
      ),
    );
  }
}
