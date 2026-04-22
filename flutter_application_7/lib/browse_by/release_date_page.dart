import 'package:flutter/material.dart';
import 'release_decade_page.dart';

class ReleaseDatePage extends StatelessWidget {
  const ReleaseDatePage({super.key});

  final decades = const [
    "Upcoming",
    "2020s",
    "2010s",
    "2000s",
    "1990s",
    "1980s",
    "1970s",
    "1960s",
    "1950s",
    "1940s",
    "1930s",
    "1920s",
    "1910s",
    "1900s",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F23),
        title: const Text("Release Date", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        itemCount: decades.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white12),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              decades[index],
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white60),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReleaseDecadePage(decade: decades[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
