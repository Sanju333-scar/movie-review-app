import 'package:flutter/material.dart';
import 'package:flutter_application_7/screens/cine_rev.dart';
import 'package:flutter_application_7/screens/search_result_page.dart';
import '../../services/tmdb_service.dart';
import '../../widgets/app_bottom_nav.dart';
import '../services/event_service.dart';
import 'package:flutter_application_7/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MovieDetailPage extends StatefulWidget {
  final int movieId;

  const MovieDetailPage({super.key, required this.movieId});

  @override
  State<MovieDetailPage> createState() => _MovieDetailPageState();
}

class _MovieDetailPageState extends State<MovieDetailPage>
    with SingleTickerProviderStateMixin {
  final TMDBService _tmdb = TMDBService();
  Map<String, dynamic>? data;
  bool isLoading = true;
  late TabController _tabController;

  bool isWatched = false;
  bool isLiked = false;
  bool isWatchlisted = false;
  double userRating = 0.0;
  String? userReview;

  final List<Map<String, dynamic>> _reviews = [];

  int? userId;

  // INIT
  @override
  void initState() {
    super.initState();
    _loadUserId();
    _tabController = TabController(length: 7, vsync: this);
    _load();
    _loadReviews();
  }

List<Map<String, dynamic>> movieReviews = [];

Future<void> _loadReviews() async {
  try {
    final reviews = await ApiService.getMovieReviews(widget.movieId);

    setState(() {
      movieReviews = reviews.map<Map<String, dynamic>>((r) {
        return {
          "user": r["username"] ?? "Anonymous",
          "rating": r["rating"] != null
              ? (r["rating"] as num).toDouble()
              : 0.0,
          "comment": r["review_text"] ?? "",
          "date": r["created_at"] ?? "",
        };
      }).toList();
    });

  } catch (e) {
    debugPrint("❌ Error fetching reviews: $e");
  }
}

  // LOAD USER ID
  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt("user_id");

    if (userId == null) {
      print("⚠️ ERROR: User id missing from shared pref");
    } else {
      print("Loaded user_id = $userId");
    }
  }

  // LOAD MOVIE + SYNC + EVENTS
  Future<void> _load() async {
    setState(() => isLoading = true);
    try {
      data = await _tmdb.getMovieDetails(widget.movieId);
      await saveMovieToBackend();
      await _sendEvent("view");
      await _loadUserActivity(); // 🔥 Load likes, rating, reviews, watchlist
    } catch (e) {
      debugPrint('Detail load error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // SYNC MOVIE DATA
  Future<void> saveMovieToBackend() async {
    if (data == null) return;

    final genres = (data!['genres'] as List<dynamic>)
        .map((g) => g['name'] as String)
        .toList();

    try {
      final ok = await ApiService.addMovie(
        tmdbId: widget.movieId,
        title: data!['title'],
        overview: data!['overview'],
        releaseDate: data!['release_date'] ?? "",
        posterPath: data!['poster_path'] ?? "",
        popularity: (data!['popularity'] as num).toDouble(),
        genres: genres,
      );

      print("MOVIE SYNCED: $ok");
    } catch (e) {
      print("Movie sync error: $e");
    }
  }

  // SEND EVENT TO BACKEND
  Future<void> _sendEvent(String eventType, {double? value}) async {
    if (userId == null) {
      print("❌ EVENT FAILED — userId is NULL");
      return;
    }

    if (data == null) return;

    try {
      await EventService.sendEvent(
        userId: userId!,
        movieId: widget.movieId,
        eventType: eventType,
        value: value,
        title: data?['title'],
        overview: data?['overview'],
        posterPath: data?['poster_path'],
        releaseDate: data?['release_date'],
        popularity: data?['popularity'],
      );
    } catch (e) {
      debugPrint('Event send error: $e');
    }
  }

  
  

  // LOAD LIKE, WATCHLIST, RATING, REVIEW
  Future<void> _loadUserActivity() async {
  if (userId == null) {
    print("⚠️ Cannot load events — userId NULL");
    return;
  }

  try {
    final activity = await ApiService.getUserMovieActivity(
      userId!,
      widget.movieId,
    );

    setState(() {
      isLiked = activity["liked"];
      isWatchlisted = activity["watchlisted"];

      // ⭐ My own review (rating + text)
      if (activity["my_review"] != null) {
        userRating = (activity["my_review"]["rating"] as num).toDouble();
      }
    });

    print("Activity loaded successfully.");
  } catch (e) {
    print("Activity load error: $e");
  }
}


  // BOTTOM SHEET ACTIONS
  void _openOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data?['title'] ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionItem(
                    icon: Icons.visibility,
                    label: isWatched ? "Watched" : "Watch",
                    onTap: () async {
                      setState(() => isWatched = !isWatched);
                      await _sendEvent("view");
                      Navigator.pop(context);
                    },
                  ),

                  _actionItem(
                    icon: Icons.favorite,
                    label: isLiked ? "Liked" : "Like",
                    color: isLiked ? Colors.red : Colors.white,
                    onTap: () async {
                      setState(() => isLiked = !isLiked);
                      await _sendEvent("like");
                      Navigator.pop(context);
                    },
                  ),

                  _actionItem(
                    icon: Icons.playlist_add,
                    label: "Watchlist",
                    color:
                        isWatchlisted ? Colors.green : Colors.white,
                    onTap: () async {
                      setState(() =>
                          isWatchlisted = !isWatchlisted);
                      await _sendEvent("watchlist");
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Rating stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < userRating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () async {
                      setState(() => userRating = index + 1.0);
                      await _sendEvent("rate", value: userRating);
                    },
                  );
                }),
              ),

              const Text("Rate",
                  style: TextStyle(color: Colors.grey)),
              const Divider(color: Colors.grey),

              ListTile(
                leading:
                    const Icon(Icons.add, color: Colors.white),
                title: const Text("Add Review",
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showReviewDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // REVIEW DIALOG
  void _showReviewDialog() {
    final controller = TextEditingController(text: userReview);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1C),
        title: const Text("Add Review",
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Write your review...",
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel",
                style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child:
                const Text("Save", style: TextStyle(color: Colors.blue)),
            onPressed: () async {
              if (userId == null) {
                print("❌ REVIEW FAILED — userId is NULL");
                Navigator.pop(context);
                return;
              }

              setState(() => userReview = controller.text);

              if (userReview != null &&
                  userReview!.isNotEmpty) {
                setState(() {
                  _reviews.insert(0, {
                    "user": "You",
                    "rating":
                        userRating > 0 ? userRating : 4.0,
                    "comment": userReview,
                  });
                });

                final success = await ApiService.addReview(
                  userId: userId!,
                  movieId: widget.movieId,
                  rating:
                      userRating > 0 ? userRating : 4.0,
                  reviewText: userReview,
                );

                print("REVIEW SENT: $success");
              }

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _actionItem({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getDirectorName() {
    final crew =
        data?['credits']?['crew'] as List<dynamic>? ?? [];
    final dir = crew.firstWhere(
      (c) => c['job'] == 'Director',
      orElse: () => null,
    );

    return dir != null ? dir['name'] : 'Unknown';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert,
                color: Colors.white),
            onPressed: _openOptions,
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Colors.green))
          : _buildContent(),

      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const CineRev()),
            );
          }

          if (i == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchResultPage()),
            );
          }
        },
      ),
    );
  }

  // BUILD MAIN UI
  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data != null) _buildHeader(),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(data?['overview'] ?? '',
                    style: const TextStyle(
                        color: Colors.white70)),
                const SizedBox(height: 20),

                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.green,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white54,
                  isScrollable: true,
                  tabs: const [
                    Tab(text: 'Cast'),
                    Tab(text: 'Crew'),
                    Tab(text: 'Details'),
                    Tab(text: 'Genre'),
                    Tab(text: 'Releases'),
                    Tab(text: 'Reviews'),
                    Tab(text: 'AI'),
                  ],
                ),

                SizedBox(
                  height: 400,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCast(),
                      _buildCrew(),
                      
                      _buildDetails(),
                      _buildGenres(),
                      _buildReleases(),
                      _buildReviews(),
                      _buildAIRecommendations(),
                    ],
                  ),
                ),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Image.network(
          data?['poster_path'] != null
              ? "https://image.tmdb.org/t/p/w500${data!['poster_path']}"
              : "https://via.placeholder.com/500x750?text=No+Image",
          width: double.infinity,
          fit: BoxFit.cover,
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.4)
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                data?['title'] ?? '',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '${data?['release_date']?.toString().split('-').first ?? ''} • Directed by ${_getDirectorName()}',
                style: const TextStyle(
                    color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                '⭐ ${data?['vote_average']?.toStringAsFixed(1) ?? 'N/A'}',
                style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // CAST TAB
  Widget _buildCast() {
    final cast =
        data?['credits']?['cast'] as List<dynamic>? ?? [];

    return ListView.builder(
      itemCount: cast.length,
      itemBuilder: (context, i) {
        final c = cast[i];

        return ListTile(
          leading: c['profile_path'] != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(
                      'https://image.tmdb.org/t/p/w200${c['profile_path']}'))
              : const CircleAvatar(
                  child: Icon(Icons.person)),
          title: Text(c['name'] ?? '',
              style:
                  const TextStyle(color: Colors.white)),
          subtitle: Text(c['character'] ?? '',
              style:
                  const TextStyle(color: Colors.white54)),
        );
      },
    );
  }
Widget _buildAIRecommendations() {
  return FutureBuilder(
    future: ApiService.getSimilarMovies(widget.movieId),
    builder: (context, snapshot) {

      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.green),
        );
      }

      if (snapshot.hasError) {
        return Text(
          "Error: ${snapshot.error}",
          style: const TextStyle(color: Colors.red),
        );
      }

      if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
        return const Text(
          "No recommendations",
          style: TextStyle(color: Colors.white),
        );
      }

      final movies = snapshot.data as List;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            "AI Recommended",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: movies.length,
              itemBuilder: (context, i) {
                final m = movies[i];

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Image.network(
                        "https://image.tmdb.org/t/p/w200${m['poster_path']}",
                        width: 100,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: 100,
                        child: Text(
                          m['title'] ?? "No title",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          )
        ],
      );
    },
  );
}
  // CREW TAB
  Widget _buildCrew() {
    final crew =
        data?['credits']?['crew'] as List<dynamic>? ?? [];

    return ListView.builder(
      itemCount: crew.length,
      itemBuilder: (context, i) {
        final c = crew[i];

        return ListTile(
          title: Text(c['name'] ?? '',
              style:
                  const TextStyle(color: Colors.white)),
          subtitle: Text(c['job'] ?? '',
              style:
                  const TextStyle(color: Colors.white54)),
        );
      },
    );
  }

  // DETAILS TAB
  Widget _buildDetails() {
    final countries = (data?['production_countries']
            as List?) ??
        [];
    final studios =
        (data?['production_companies'] as List?) ?? [];
    final lang = data?['original_language'] ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        'Studios: ${studios.map((e) => e['name']).join(", ")}\n'
        'Countries: ${countries.map((e) => e['name']).join(", ")}\n'
        'Language: $lang',
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }

  // GENRES TAB
  Widget _buildGenres() {
    final genres =
        data?['genres'] as List<dynamic>? ?? [];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 8,
        children: genres
            .map((g) => Chip(
                  label: Text(g['name']),
                  backgroundColor: Colors.green,
                  labelStyle: const TextStyle(
                      color: Colors.white),
                ))
            .toList(),
      ),
    );
  }

  // RELEASE DATE TAB
  Widget _buildReleases() {
    final release = data?['release_date'] ?? 'N/A';

    return Center(
      child: Text('Release Date: $release',
          style: const TextStyle(color: Colors.white70)),
    );
  }

  // REVIEWS TAB
Widget _buildReviews() {
  if (movieReviews.isEmpty) {
    return const Center(
      child: Text(
        "No reviews yet",
        style: TextStyle(color: Colors.white54, fontSize: 16),
      ),
    );
  }

  return ListView(
    padding: const EdgeInsets.all(12),
    children: movieReviews.map((r) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFF262626),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['user'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (i) {
                      final rating = r['rating'];
                      return Icon(
                        i < rating.floor()
                            ? Icons.star
                            : i < rating
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.greenAccent,
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r['comment'],
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
    }).toList(),
  );
}
    }