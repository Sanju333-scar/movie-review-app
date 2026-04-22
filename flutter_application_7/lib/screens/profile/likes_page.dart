import 'package:flutter/material.dart';

class LikesPage extends StatelessWidget {
  const LikesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        title: const Text("likes", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C1F23),
      ),
      body: const Center(
        child: Text("likes",
            style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
