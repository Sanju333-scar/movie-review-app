import 'package:flutter/material.dart';
import '../../models/tmdb_movie_model.dart';
import '../../services/tmdb_service.dart';
import 'movie_detail_page.dart';
import '../screens/profile/followers_page.dart'; 
import '../screens/profile/following_page.dart';
import '../screens/profile/likes_page.dart';
import '../screens/profile/profile_settings_page.dart';
import '../screens/profile/reviews_page.dart';
import '../screens/profile/watchlist_page.dart';
import '../screens/profile/films_page.dart';
import '../screens/profile/add_favorite_page.dart';
import '../screens/profile/user_lists_page.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final TMDBService _service = TMDBService();

  List<TMDBMovie> favorites = [];
  List<TMDBMovie> recentActivity = [];

  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final favMovies = await _service.getTopRatedMovies();
      final recent = await _service.getPopularMovies();

      setState(() {
        favorites = favMovies.take(2).toList();
        recentActivity = recent.take(3).toList();
      });
    } catch (e) {
      debugPrint("Error loading profile data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

 void _addFavorite() async {
  final TMDBMovie? selected = await Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddFavoritePage()),
  );

  if (selected != null) {
    setState(() {
      favorites.add(selected);
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF1C1F23),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1C1F23),
          elevation: 0,
          centerTitle: true,
          title: const Text("sudheee",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
              );
            },
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.green,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: "Profile"),
              Tab(text: "Lists"),
              Tab(text: "Watchlist"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            :// ... inside your Scaffold body
TabBarView(
  controller: _tabController,
  children: [
    _buildProfileTab(),
    // Corrected UserListsPage placement
    const UserListsPage(), 
    const WatchlistPage(),
  ],
),
      ),
    );
  }

  // ------------------------ PROFILE TAB ------------------------
  Widget _buildProfileTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: Colors.green,
      backgroundColor: Colors.black,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          const SizedBox(height: 10),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.person, size: 50, color: Colors.white54),
            ),
          ),
          const SizedBox(height: 20),

          // FAVORITES
          _buildSectionHeader("FAVORITES", onAdd: _addFavorite),
          _buildMovieGrid(favorites),

          const SizedBox(height: 20),

          // RECENT ACTIVITY
          _buildSectionHeader("RECENT ACTIVITY"),
          _buildMovieRow(recentActivity),

          const SizedBox(height: 25),

          // STATS (clickable)
          _buildStatsSection(),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onAdd}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          if (onAdd != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }

  Widget _buildMovieGrid(List<TMDBMovie> movies) {
    if (movies.isEmpty) {
      return Container(
        height: 160,
        alignment: Alignment.center,
        child: const Text("No favorites yet",
            style: TextStyle(color: Colors.white54)),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return _buildMovieCard(movie);
        },
      ),
    );
  }

  Widget _buildMovieRow(List<TMDBMovie> movies) {
    if (movies.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        child: const Text("No recent activity",
            style: TextStyle(color: Colors.white54)),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final movie = movies[index];
          return _buildMovieCard(movie);
        },
      ),
    );
  }

  Widget _buildMovieCard(TMDBMovie movie) {
    final imageUrl =
        movie.posterUrl ?? 'https://via.placeholder.com/500x750?text=No+Image';
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MovieDetailPage(movieId: movie.id ?? 0)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 120,
          height: 170,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    final stats = [
      {"label": "", "value": "", "page": const FilmsPage()},
      {"label": "", "value": "", "page": const ReviewsPage()},
      {"label": "", "value": "", "page": const WatchlistPage()},
      {"label": "", "value": "", "page": const LikesPage()},
      {"label": "", "value": "", "page": const FollowingPage()},
      {"label": "", "value": "", "page": const FollowersPage()},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: stats
          .map(
            (s) => InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => s["page"] as Widget),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(s["label"] as String,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 15)),
                    Text(s["value"] as String,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 15)),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
