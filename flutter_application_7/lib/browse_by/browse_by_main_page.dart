import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import 'movies_by_filter_page.dart';

class BrowseByPage extends StatefulWidget {
  const BrowseByPage({super.key});

  @override
  State<BrowseByPage> createState() => _BrowseByPageState();
}

class _BrowseByPageState extends State<BrowseByPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TMDBService _tmdb = TMDBService();

  List<Map<String, dynamic>> genres = [];
  List<Map<String, dynamic>> countries = [];
  List<Map<String, dynamic>> languages = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    loadData();
  }

  Future<void> loadData() async {
    final g = await _tmdb.getGenres();
    final c = await _tmdb.getCountries();
    final l = await _tmdb.getLanguages();

    setState(() {
      genres = g;
      countries = c;
      languages = l;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F23),
        title: const Text(
          "Browse by",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.greenAccent,
          tabs: const [
            Tab(text: "Genre"),
            Tab(text: "Country"),
            Tab(text: "Language"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                buildList(genres, "genre"),
                buildList(countries, "country"),
                buildList(languages, "language"),
              ],
            ),
    );
  }

  Widget buildList(List<Map<String, dynamic>> items, String type) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Colors.white12),
      itemBuilder: (context, index) {
        final item = items[index];

        String title = "";
        String value = "";

        if (type == "genre") {
          title = item["name"];
          value = item["id"].toString(); // ⭐ genre ID
        }

        if (type == "country") {
          title = item["english_name"] ?? item["name"];
          value = item["iso_3166_1"]; // ⭐ country code
        }

        if (type == "language") {
          title = item["english_name"] ?? item["name"];
          value = item["iso_639_1"]; // ⭐ language code
        }

        return ListTile(
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.white54,
          ),
         onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MoviesByFilterPage(
        title: title,       // Displays the name (e.g., "Action")
        type: type,        // "genre", "country", or "language"
        value: value,      // The ID or ISO code
      ),
    ),
  );
},
        );
      },
    );
  }
}
