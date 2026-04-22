import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import '../models/tmdb_movie_model.dart';
import '../screens/movie_detail_page.dart';



class YearPage extends StatefulWidget {
  final String year;
  const YearPage({super.key, required this.year});

  @override
  State<YearPage> createState() => _YearPageState();
}

class _YearPageState extends State<YearPage> {
  final TMDBService _tmdb = TMDBService();
  late Future<List<TMDBMovie>> movies;

  @override
  void initState() {
    super.initState();

    movies = _tmdb.getMoviesByReleaseDate(
      fromDate: '${widget.year}-01-01',
      toDate: '${widget.year}-12-31',
      page: 1,
      sortBy: 'popularity.desc', // ⭐ MOST IMPORTANT
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F23),
        title: Text(
          widget.year,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<TMDBMovie>>(
        future: movies,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No movies found",
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final movieList = snapshot.data!;

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: movieList.length,
            itemBuilder: (context, index) {
              final movie = movieList[index];

              // 🚫 Skip movies without posters
              if (movie.posterPath == null) {
                return const SizedBox.shrink();
              }

             return GestureDetector(
  onTap: () {
    if (movie.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MovieDetailPage(movieId: movie.id!), // ✅ force unwrapped
        ),
      );
    }
  },
  child: ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.network(
      "https://image.tmdb.org/t/p/w500${movie.posterPath}",
      fit: BoxFit.cover,
    ),
  ),
);

            },
          );
        },
      ),
    );
  }
}
