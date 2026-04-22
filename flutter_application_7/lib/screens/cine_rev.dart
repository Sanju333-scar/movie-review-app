import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_7/screens/movie_detail_page.dart';
import 'package:flutter_application_7/screens/search_page.dart';
import 'package:flutter_application_7/screens/add_film_page.dart';
import 'package:flutter_application_7/screens/profile_page.dart';
import 'package:flutter_application_7/widgets/app_bottom_nav.dart';
import 'package:flutter_application_7/services/tmdb_service.dart';
import 'package:flutter_application_7/services/recommendation_service.dart';
import 'package:flutter_application_7/models/tmdb_movie_model.dart';
import 'package:flutter_application_7/models/recommendation_model.dart';
import 'package:flutter_application_7/screens/profile/user_lists_page.dart';

class CineRev extends StatefulWidget {
  const CineRev({super.key});

  @override
  State<CineRev> createState() => _CineRevState();
}

class _CineRevState extends State<CineRev> {
  final TMDBService _service = TMDBService();
  final RecommendationService _recommendationService =
      RecommendationService();

  int _selectedIndex = 0;
  int? _userId;

  List<TMDBMovie> _popular = [];
  List<TMDBMovie> _topRated = [];
  List<TMDBMovie> _upcoming = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initUserAndLoadMovies();
  }

  Future<List<Recommendation>>? _recommendationFuture;

  /// 🔹 Load user + movies
  Future<void> _initUserAndLoadMovies() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');

    if (_userId != null) {
      _recommendationFuture =
          _recommendationService.fetchRecommendations(_userId!);
    }

    await _loadAllMovies();
  }

  /// 🔹 Load movies
  Future<void> _loadAllMovies() async {
    setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        _service.getPopularMovies().catchError((_) => <TMDBMovie>[]),
        _service.getTopRatedMovies().catchError((_) => <TMDBMovie>[]),
        _service.getUpcomingMovies().catchError((_) => <TMDBMovie>[]),
      ]);

      setState(() {
        _popular = results[0];
        _topRated = results[1];
        _upcoming = results[2];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔹 Bottom Navigation Pages
  List<Widget> get _pages => [
        _buildHomePage(),
        const SearchPage(),
        const AddFilmPage(),
        const ProfilePage(),
      ];

  /// 🔹 HOME PAGE WITH TABS
  Widget _buildHomePage() {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1F23),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1F23),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'CINEREV',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.green,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'FILMS'),
              
              Tab(text: 'LISTS'),
              Tab(text: 'RECOMMENDED'),
            ],
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            : TabBarView(
                children: [
                  _buildFilmsTab(),
                  const UserListsPage(),
                  _buildRecommendedTab(),
                ],
              ),
      ),
    );
  }

  /// 🔹 FILMS TAB
  Widget _buildFilmsTab() {
    return RefreshIndicator(
      onRefresh: _loadAllMovies,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMovieSection("Popular this Week", _popular),
            _buildMovieSection("Top Rated", _topRated),
            _buildMovieSection("Upcoming", _upcoming),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  /// 🔹 MOVIE SECTION
  Widget _buildMovieSection(String title, List<TMDBMovie> movies) {
    if (movies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          "$title (No data)",
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 210,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: movies.length > 10 ? 10 : movies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final movie = movies[index];
                final imageUrl = movie.posterUrl ??
                    'https://via.placeholder.com/500x750?text=No+Image';

               return Material(
  color: Colors.transparent,
  child: InkWell(
    borderRadius: BorderRadius.circular(8),
    onTap: () {
  if (movie.id == null) return;

  // ✅ Navigate IMMEDIATELY (no waiting)
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MovieDetailPage(movieId: movie.id!),
    ),
  );

  // ✅ Run API in background (non-blocking)
  if (_userId != null) {
    _recommendationService
        .addToSeed(_userId!, movie.id!)
        .catchError((e) {
      print("Seed error: $e");
    });
  }
},
    child: Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 120,
            height: 170,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 120,
          child: Text(
            movie.title ?? 'Untitled',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  ),
);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 RECOMMENDED TAB
Widget _buildRecommendedTab() {
  if (_userId == null) {
    return const Center(
      child: Text(
        "Please log in to see recommendations",
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  return FutureBuilder<List<Recommendation>>(
    future: _recommendationFuture,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.green),
        );
      }

      if (snapshot.hasError) {
        return const Center(
          child: Text(
            "Error loading recommendations",
            style: TextStyle(color: Colors.white),
          ),
        );
      }

      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return const Center(
          child: Text(
            "No recommendations yet",
            style: TextStyle(color: Colors.white),
          ),
        );
      }

      final recs = snapshot.data!;

      return GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.66,
          crossAxisSpacing: 10,
          mainAxisSpacing: 12,
        ),
        itemCount: recs.length,
        itemBuilder: (context, index) {
          final rec = recs[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailPage(
                    movieId: rec.tmdbId,
                  ),
                ),
              );
            },
            child: Column(
              children: [
          ClipRRect(
  borderRadius: BorderRadius.circular(10),
  child: rec.fullImageUrl.isEmpty
      ? Container(
          width: 120,
          height: 180,
          color: Colors.grey[800],
          child: const Icon(
            Icons.movie,
            color: Colors.white54,
            size: 40,
          ),
        )
      : Image.network(
          rec.fullImageUrl,
          width: 120,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 120,
              height: 180,
              color: Colors.grey[800],
              child: const Icon(
                Icons.movie,
                color: Colors.white54,
                size: 40,
              ),
            );
          },
        ),
),
                const SizedBox(height: 6),
                SizedBox(
                  width: 120,
                  child: Text(
                    rec.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

  /// 🔹 ROOT SCAFFOLD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}