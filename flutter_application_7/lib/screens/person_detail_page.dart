import 'package:flutter/material.dart';
import '../services/tmdb_service.dart';
import 'movie_detail_page.dart';

class PersonDetailPage extends StatefulWidget {
  final int personId;
  const PersonDetailPage({super.key, required this.personId});

  @override
  State<PersonDetailPage> createState() => _PersonDetailPageState();
}

class _PersonDetailPageState extends State<PersonDetailPage> {
  final TMDBService _tmdb = TMDBService();

  Map<String, dynamic>? personDetails;
  List<dynamic> combinedCredits = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadPersonData();
  }

  Future<void> loadPersonData() async {
    final details = await _tmdb.getPersonDetails(widget.personId);
    final credits = await _tmdb.getPersonCombinedCredits(widget.personId);

    setState(() {
      personDetails = details;
      combinedCredits = credits;
      loading = false;
    });
  }

  List<dynamic> getFilteredMovies() {
    if (combinedCredits.isEmpty) return [];

    final department = personDetails?["known_for_department"] ?? "";

    if (department == "Acting") {
      return combinedCredits.where((m) => m["media_type"] == "movie").toList();
    }

    return combinedCredits
        .where((m) =>
            m["media_type"] == "movie" &&
            (m["job"] != null || m["department"] != null))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1C1F23),
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    final profile = personDetails?["profile_path"] != null
        ? "https://image.tmdb.org/t/p/w300${personDetails!["profile_path"]}"
        : null;

    final movies = getFilteredMovies();

    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F23),
        elevation: 0,
        title: Text(
          personDetails?["name"] ?? "",
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// PROFILE IMAGE + BIO
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: profile != null
                      ? Image.network(profile, width: 120)
                      : Container(
                          width: 120,
                          height: 160,
                          color: Colors.grey.shade800,
                          child: const Center(
                            child: Text("No Image",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ),
                ),
                const SizedBox(width: 16),

                Expanded(
                  child: Text(
                    personDetails?["biography"]?.toString().trim().isEmpty == true
                        ? "No biography available."
                        : personDetails!["biography"],
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// MOVIES SECTION
            Text(
              "Movies",
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            movies.isEmpty
                ? const Text(
                    "No movies available.",
                    style: TextStyle(color: Colors.white70),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: movies.length,
                    itemBuilder: (context, i) {
                      final m = movies[i];
                      final movieId = m["id"];

                      final poster = m["poster_path"] != null
                          ? "https://image.tmdb.org/t/p/w185${m["poster_path"]}"
                          : null;

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MovieDetailPage(movieId: movieId),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: poster != null
                                    ? Image.network(poster, width: 60)
                                    : Container(
                                        width: 60,
                                        height: 90,
                                        color: Colors.grey.shade800,
                                        child: const Center(
                                          child: Icon(Icons.movie,
                                              color: Colors.white54),
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  m["title"] ?? "",
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
