import 'package:flutter/material.dart';

class FollowingPage extends StatelessWidget {
  const FollowingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        title: const Text("following", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C1F23),
      ),
      body: const Center(
        child: Text("following",
            style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
