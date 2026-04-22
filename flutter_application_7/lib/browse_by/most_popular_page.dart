import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';

class MostPopularPage extends StatefulWidget {
  final String title; // <-- add this

  const MostPopularPage({super.key, required this.title}); // <-- add required title

  @override
  State<MostPopularPage> createState() => _MostPopularPageState();
}

class _MostPopularPageState extends State<MostPopularPage> {
  final TMDBService _tmdb = TMDBService();
  List movies = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMovies();
  }

  Future<void> loadMovies() async {
    movies = await _tmdb.getPopularMovies();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F23),
        title: Text(widget.title), // <-- use widget.title here
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
                  child: movie.posterPath == null
                      ? Container(color: Colors.grey[800])
                      : Image.network(
                          "https://image.tmdb.org/t/p/w500${movie.posterPath}",
                          fit: BoxFit.cover,
                        ),
                );
              },
            ),
    );
  }
}
