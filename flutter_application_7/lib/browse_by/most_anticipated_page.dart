import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
class MostAnticipatedPage extends StatefulWidget {
  const MostAnticipatedPage({super.key});

  @override
  State<MostAnticipatedPage> createState() => _MostAnticipatedPageState();
}

class _MostAnticipatedPageState extends State<MostAnticipatedPage> {
  final TMDBService _tmdb = TMDBService();
  List movies = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMovies();
  }

  Future<void> loadMovies() async {
    movies = await _tmdb.getUpcomingMovies();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F23),
        title: const Text("Most Anticipated"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: movies.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.58,
              ),
              itemBuilder: (context, index) {
                final movie = movies[index];

                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    "https://image.tmdb.org/t/p/w500${movie.posterPath}",
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
    );
  }
}
