import 'package:flutter/material.dart';
import 'package:flutter_application_7/screens/cine_rev.dart';
import 'package:flutter_application_7/screens/movie_detail_page.dart';
import 'package:flutter_application_7/screens/person_detail_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tmdb_service.dart';
import '../../models/tmdb_movie_model.dart';

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({super.key});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TMDBService _tmdb = TMDBService();

  List<TMDBMovie> movies = [];
  List<dynamic> peopleResults = [];
  bool isLoading = false;
  bool hasSearched = false;

  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _saveRecent(String query) async {
    final prefs = await SharedPreferences.getInstance();
    if (query.trim().isEmpty) return;

    recentSearches.remove(query);
    recentSearches.insert(0, query);

    if (recentSearches.length > 10) {
      recentSearches = recentSearches.sublist(0, 10);
    }

    await prefs.setStringList('recent_searches', recentSearches);
  }

  Future<void> searchAll(String query) async {
    if (query.isEmpty) return;

    setState(() {
      hasSearched = true;
      isLoading = true;
      movies.clear();
      peopleResults.clear();
    });

    await _saveRecent(query);

    try {
      movies = await _tmdb.searchMovies(query);
      peopleResults = await _tmdb.searchPeopleAndCompanies(query);
    } catch (e) {
      debugPrint("Error: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget buildFilmsTab() {
    if (!hasSearched) return _buildRecentSearchesView();
    if (isLoading) return const Center(child: CircularProgressIndicator(color: Colors.green));
    if (movies.isEmpty) {
      return const Center(child: Text("No films found", style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: movies.length,
      itemBuilder: (context, i) {
        final m = movies[i];
        return ListTile(
          leading: m.posterUrlSmall != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(m.posterUrlSmall!, width: 55))
              : const Icon(Icons.movie, color: Colors.white54),
          title: Text(m.title ?? "", style: const TextStyle(color: Colors.white)),
          subtitle:
              Text(m.releaseDate ?? "N/A", style: const TextStyle(color: Colors.white60)),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailPage(movieId: m.id ?? 0),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRecentSearchesView() {
    if (recentSearches.isEmpty) {
      return const Center(
        child: Text("No recent searches", style: TextStyle(color: Colors.white70)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: recentSearches.length,
      itemBuilder: (context, index) {
        final q = recentSearches[index];
        return ListTile(
          title: Text(q, style: const TextStyle(color: Colors.white70)),
          onTap: () {
            _searchController.text = q;
            searchAll(q);
          },
        );
      },
    );
  }

 Widget buildPeopleTab() {
  if (!hasSearched) return _buildPlaceholder("people");
  if (isLoading) {
    return const Center(child: CircularProgressIndicator(color: Colors.green));
  }

  final people = peopleResults.where((e) => e["media_type"] == "person").toList();

  if (people.isEmpty) {
    return const Center(
      child: Text(
        "No cast or crew found",
        style: TextStyle(color: Colors.white70),
      ),
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: people.length,
    itemBuilder: (context, index) {
      final p = people[index];
      final personId = p["id"];

      final image = p["profile_path"] != null
          ? "https://image.tmdb.org/t/p/w185${p["profile_path"]}"
          : null;

      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PersonDetailPage(personId: personId),
            ),
          );
        },
        child: FutureBuilder<String>(
          future: _tmdb.buildPersonDescription(personId),
          builder: (context, snapshot) {
            final subtitle =
                snapshot.hasData ? snapshot.data! : "Loading details...";

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PERSON IMAGE
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(8),
                      image: image != null
                          ? DecorationImage(
                              image: NetworkImage(image),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: image == null
                        ? const Center(
                            child: Text("NA",
                                style: TextStyle(color: Colors.white54)),
                          )
                        : null,
                  ),

                  const SizedBox(width: 12),

                  // NAME + DESCRIPTION
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p["name"] ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}



  Widget _buildPlaceholder(String label) {
    return Center(
      child: Text("Search $label",
          style: const TextStyle(color: Colors.white70, fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F23),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const CineRev())),
        ),
        titleSpacing: 0,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2E33),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.green,
            decoration: const InputDecoration(
              hintText: "Search...",
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: searchAll,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          isScrollable: true,
          tabs: const [
            Tab(text: "Films"),
            Tab(text: "Reviews"),
            Tab(text: "Lists"),
            Tab(text: "Cast, Crew or Studios"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildFilmsTab(),
          _buildPlaceholder("reviews"),
          _buildPlaceholder("lists"),
          buildPeopleTab(),
          
        ],
      ),
    );
  }
}