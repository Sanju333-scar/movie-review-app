 import 'package:flutter/material.dart';

class FeaturedListsPage extends StatelessWidget {
  const FeaturedListsPage({super.key});

  final List<Map<String, dynamic>> lists = const [
    {
      "title": "Most Fans on Letterboxd",
      "posters": [
        "https://....jpg",
        "https://....jpg",
        "https://....jpg"
      ]
    },
    {
      "title": "One Million Watched Club",
      "posters": [
        "https://....jpg",
        "https://....jpg",
        "https://....jpg"
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Featured Lists")),
      body: ListView.builder(
        itemCount: lists.length,
        itemBuilder: (context, index) {
          final item = lists[index];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  item["title"],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: item["posters"].length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, pIndex) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item["posters"][pIndex],
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}   