import 'package:flutter/material.dart';

class FilmsPage extends StatelessWidget {
  const FilmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        title: const Text(
          "Films",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1C1F23),
      ),
      body: const Center(
        child: Text(
          "Your watched films will appear here",
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
