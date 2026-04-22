import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../models/tmdb_movie_model.dart';
import 'add_film_review_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchAndSelectMoviePage extends StatefulWidget {
  const SearchAndSelectMoviePage({super.key});

  @override
  State<SearchAndSelectMoviePage> createState() =>
      _SearchAndSelectMoviePageState();
}

class _SearchAndSelectMoviePageState extends State<SearchAndSelectMoviePage> {
  final TextEditingController _controller = TextEditingController();
  final TMDBService _tmdb = TMDBService();

  List<TMDBMovie> movies = [];
  bool loading = false;

  List<String> recentSearches = [];

  @override
  void initState() {
    super.initState();
    loadRecentSearches();
  }

  /// Load Recent Searches
  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentSearches = prefs.getStringList("recent_searches") ?? [];
    });
  }

  /// Save a Search Term
  Future<void> saveSearch(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    recentSearches.remove(query); // remove duplicate
    recentSearches.insert(0, query); // add on top

    if (recentSearches.length > 10) {
      recentSearches = recentSearches.sublist(0, 10); // keep 10 max
    }

    prefs.setStringList("recent_searches", recentSearches);
  }

  /// Delete ALL recent searches
  Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("recent_searches");

    setState(() {
      recentSearches = [];
    });
  }

  /// Delete ONE recent search
  Future<void> deleteSingleSearch(String query) async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches.remove(query);
    await prefs.setStringList("recent_searches", recentSearches);

    setState(() {});
  }

  /// Perform search and save query
  void search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => movies = []);
      return;
    }

    setState(() => loading = true);

    final results = await _tmdb.searchMovies(q);
    await saveSearch(q);

    setState(() {
      movies = results;
      loading = false;
    });
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
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          onSubmitted: search,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: const InputDecoration(
            hintText: "Search movies...",
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())

          // Show Recent Searches
          : _controller.text.isEmpty && movies.isEmpty
              ? Column(
                  children: [
                    if (recentSearches.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: clearRecentSearches,
                          child: const Text(
                            "Clear All",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: recentSearches.length,
                        itemBuilder: (context, index) {
                          final query = recentSearches[index];
                          return ListTile(
                            title: Text(
                              query,
                              style: const TextStyle(color: Colors.white),
                            ),
                            leading: const Icon(Icons.history,
                                color: Colors.white54),

                            trailing: IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white38),
                              onPressed: () => deleteSingleSearch(query),
                            ),

                            onTap: () {
                              _controller.text = query;
                              search(query);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                )

          // Normal Search Results
          : movies.isEmpty
              ? const Center(
                  child: Text(
                    "No results",
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.separated(
                  itemCount: movies.length,
                  separatorBuilder: (_, __) =>
                      Divider(color: Colors.white12, height: 1),
                  itemBuilder: (context, index) {
                    final m = movies[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddFilmReviewPage(
                              movieId: m.id!,
                              title: m.title ?? "",
                              year: m.releaseDate?.split("-").first ?? "",
                              posterUrl: m.posterUrlSmall,
                            ),
                          ),
                        );
                      },
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: m.posterUrlSmall != null
                            ? Image.network(
                                m.posterUrlSmall!,
                                width: 55,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 55,
                                height: 80,
                                color: Colors.white12,
                                child: const Icon(Icons.movie,
                                    color: Colors.white),
                              ),
                      ),
                      title: Text(
                        m.title ?? "",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 17),
                      ),
                      subtitle: Text(
                        m.releaseDate ?? "",
                        style: const TextStyle(color: Colors.white54),
                      ),
                    );
                  },
                ),
    );
  }
}
