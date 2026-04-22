  import 'package:flutter/material.dart';
import 'movies_by_filter_page.dart'; // Make sure this file exists and has MoviesByFilterPage

class FilterSelectionPage extends StatelessWidget {
  final String type;
  const FilterSelectionPage({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> items = [];

    if (type == "genre") {
      items = [
        {"name": "Action", "id": 28},
        {"name": "Adventure", "id": 12},
        {"name": "Animation", "id": 16},
        {"name": "Comedy", "id": 35},
        {"name": "Crime", "id": 80},
        {"name": "Drama", "id": 18},
        {"name": "Fantasy", "id": 14},
        {"name": "Horror", "id": 27},
        {"name": "Romance", "id": 10749},
      ];
    }

    if (type == "country") {
      items = [
        {"name": "India", "code": "IN"},
        {"name": "United States", "code": "US"},
        {"name": "Japan", "code": "JP"},
        {"name": "France", "code": "FR"},
        {"name": "South Korea", "code": "KR"},
      ];
    }

    if (type == "language") {
      items = [
        {"name": "English", "code": "en"},
        {"name": "Hindi", "code": "hi"},
        {"name": "Tamil", "code": "ta"},
        {"name": "Japanese", "code": "ja"},
        {"name": "Korean", "code": "ko"},
      ];
    }

    return Scaffold(
      appBar: AppBar(title: Text("Select ${type.toUpperCase()}")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final item = items[i];
          return ListTile(
            title: Text(item["name"]),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MoviesByFilterPage(
                  type: type,
                  value: item["id"]?.toString() ?? item["code"],
                  title: item["name"],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}   