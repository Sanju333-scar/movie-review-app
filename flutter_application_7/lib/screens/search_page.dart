import 'package:flutter/material.dart';
import 'search_result_page.dart'; // import search results screen
import '../browse_by/release_date_page.dart';
import '../browse_by/genre_country_language_page.dart';
import '../browse_by/most_popular_page.dart';
import '../browse_by/highest_rated_page.dart';
import '../browse_by/most_anticipated_page.dart';
import '../browse_by/featured_lists_page.dart';


class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  final browseByItems = const [
    'Release date',
    'Genre, country or language',
    'Most popular',
    'Highest rated',
    'Most anticipated',
    'Featured lists',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          children: [
            // --- Search Bar ---
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SearchResultPage(),
                  ),
                );
              },
              child: AbsorbPointer(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: const Color(0xFF2A2E33),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- BROWSE BY SECTION ---
            const Text(
              'BROWSE BY',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),

            ...browseByItems.map(
              (item) => ListTile(
                title: Text(item,
                    style: const TextStyle(color: Colors.white, fontSize: 15)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () {
                  if (item == 'Release date') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ReleaseDatePage()),
                    );
                  } else if (item == 'Genre, country or language') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const  BrowseByPage()),
                    );
                  } else if (item == 'Most popular') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              MostPopularPage(title: 'Most Popular')),
                    );
                  } else if (item == 'Highest rated') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HighestRatedPage()),
                    );
                  } else if (item == 'Most anticipated') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MostAnticipatedPage()),
                    );
                  } else if (item == 'Featured lists') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FeaturedListsPage()),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}