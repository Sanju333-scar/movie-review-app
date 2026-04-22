import 'package:flutter/material.dart';

class ProfileSettingsPage extends StatelessWidget {
  const ProfileSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        title: const Text("profile", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C1F23),
      ),
      body: const Center(
        child: Text("profile",
            style: TextStyle(color: Colors.white70)),
      ),
    );
  }
}
