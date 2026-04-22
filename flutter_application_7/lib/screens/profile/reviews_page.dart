import 'package:flutter/material.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        title: const Text("Reviews", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C1F23),
      ),
      body: const Center(
        child: Text("User Reviews Here",
            style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
