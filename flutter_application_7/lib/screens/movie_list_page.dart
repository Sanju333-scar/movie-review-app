// lib/screens/movie_list_page.dart
import 'package:flutter/material.dart';
import '../../services/tmdb_service.dart';
import '../../models/tmdb_movie_model.dart';
import 'movie_detail_page.dart';

class MovieListPage extends StatefulWidget {
  final String title;
  final String category;

  const MovieListPage({super.key, required this.title, required this.category});

  @override
  State<MovieListPage> createState() => _MovieListPageState();
}

class _MovieListPageState extends State<MovieListPage> {
  final TMDBService _service = TMDBService();
  List<TMDBMovie> _movies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    setState(() => isLoading = true);
    try {
      List<TMDBMovie> res = [];
      if (widget.category == "popular") {
        res = await _service.getPopularMovies();
      } else if (widget.category == "top_rated") {
        res = await _service.getTopRatedMovies();
      } else if (widget.category == "upcoming") {
        res = await _service.getUpcomingMovies();
      }
      setState(() => _movies = res);
    } catch (e) {
      debugPrint('Error loading ${widget.category}: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F23),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.6,
              ),
              itemCount: _movies.length,
              itemBuilder: (context, index) {
                final movie = _movies[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MovieDetailPage(movieId: movie.id ?? 0),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: movie.posterUrl != null
                        ? Image.network(
                            movie.posterUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey[800]),
                          )
                        : Container(color: Colors.grey[800]),
                  ),
                );
              },
            ),
    );
  }
}
