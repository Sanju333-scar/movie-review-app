import 'package:flutter/material.dart';
import '../models/tmdb_movie_model.dart';
import '../services/tmdb_service.dart';
import '../screens/movie_detail_page.dart'; // Ensure the path is correct

class MoviesByFilterPage extends StatefulWidget {
  final String title;
  final String type;
  final String value;

  const MoviesByFilterPage({
    super.key,
    required this.title,
    required this.type,
    required this.value,
  });

  @override
  State<MoviesByFilterPage> createState() => _MoviesByFilterPageState();
}

class _MoviesByFilterPageState extends State<MoviesByFilterPage> {
  final TMDBService _tmdb = TMDBService();

  List<TMDBMovie> movies = [];
  int page = 1;
  bool loading = true;
  bool fetchingMore = false;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    if (fetchingMore) return;
    fetchingMore = true;

    final result = await _tmdb.getMoviesByFilter(
      type: widget.type,
      value: widget.value,
      page: page,
    );

    setState(() {
      movies.addAll(result);
      page++;
      loading = false;
      fetchingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : NotificationListener<ScrollNotification>(
              onNotification: (scroll) {
                if (scroll.metrics.pixels >
                    scroll.metrics.maxScrollExtent - 300) {
                  fetch();
                }
                return false;
              },
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: movies.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.66,
                ),
              itemBuilder: (context, i) {
  final movie = movies[i]; // This is the TMDBMovie object from your list
  
  return GestureDetector(
   onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      // If movie.id is null, it will pass 0 instead
      builder: (_) => MovieDetailPage(movieId: movie.id ?? 0), 
    ),
  );
},
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        movie.posterUrl ?? 'https://via.placeholder.com/300x450',
        fit: BoxFit.cover,
      ),
    ),
  );
},
              ),
            ),
    );
  }
}