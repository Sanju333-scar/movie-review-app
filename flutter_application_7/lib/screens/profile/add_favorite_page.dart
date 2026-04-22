import 'package:flutter/material.dart';
import '../../../models/tmdb_movie_model.dart';
import '../../../services/tmdb_service.dart';

class AddFavoritePage extends StatefulWidget {
  const AddFavoritePage({super.key});

  @override
  State<AddFavoritePage> createState() => _AddFavoritePageState();
}

class _AddFavoritePageState extends State<AddFavoritePage> {
  final TMDBService _service = TMDBService();
  List<TMDBMovie> _results = [];
  bool _isLoading = false;
  String _query = "";
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _searchMovies(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
      _query = query.trim(); // now used in the UI
    });

    try {
      final data = await _service.searchMovies(query.trim());
      setState(() {
        _results = data;
      });
    } catch (e) {
      debugPrint("Error searching movies: $e");
      // optionally show a SnackBar or an error widget
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchTap() => _searchMovies(_controller.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        title: const Text("Add Favorite", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1C1F23),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey[900],
                      hintText: "Search movies...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    textInputAction: TextInputAction.search,
                    onSubmitted: _searchMovies,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _onSearchTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.arrow_forward, color: Colors.white),
                ),
              ],
            ),
          ),

          // show message or loader
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator(color: Colors.green)),
            )
          else if (_results.isEmpty)
            Expanded(
              child: Center(
                child: _query.isEmpty
                    ? const Text("Search for a movie to add",
                        style: TextStyle(color: Colors.white54))
                    : Text("No results for \"$_query\"",
                        style: const TextStyle(color: Colors.white54)),
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      'Results for "$_query"',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final movie = _results[index];
                        final image = movie.posterUrl ??
                            'https://via.placeholder.com/500x750?text=No+Image';
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context, movie);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.image_not_supported, color: Colors.white54),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
