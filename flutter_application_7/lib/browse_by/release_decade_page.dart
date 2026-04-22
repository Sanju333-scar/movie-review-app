import 'package:flutter/material.dart';
import 'year_page.dart';

class ReleaseDecadePage extends StatelessWidget {
  final String decade;
  const ReleaseDecadePage({super.key, required this.decade});

  @override
  Widget build(BuildContext context) {
    final years = _generateYears(decade);

    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F23),
        title: Text(
          decade,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView.separated(
        itemCount: years.length,
        separatorBuilder: (_, __) => const Divider(color: Colors.white12),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(
              years[index],
              style: const TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => YearPage(year: years[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<String> _generateYears(String decade) {
    if (decade == "Upcoming") {
      return ["2029", "2028", "2027", "2026", "2025", "2024"];
    }

    if (!decade.endsWith("s")) return [];

    int base = int.parse(decade.substring(0, 4));

    return List.generate(10, (i) => (base + i).toString()).reversed.toList();
  }
}
