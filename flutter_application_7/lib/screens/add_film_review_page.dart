import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tmdb_service.dart';
import '../services/api_service.dart'; // ✅ ADD THIS

class AddFilmReviewPage extends StatefulWidget {
  final int movieId;
  final String title;
  final String year;
  final String? posterUrl;

  const AddFilmReviewPage({
    super.key,
    required this.movieId,
    required this.title,
    required this.year,
    this.posterUrl,
  });

  @override
  State<AddFilmReviewPage> createState() => _AddFilmReviewPageState();
}

class _AddFilmReviewPageState extends State<AddFilmReviewPage> {
  DateTime watchedDate = DateTime.now();
  double rating = 0;
  bool liked = false;
  bool inWatchlist = false;

  Map<String, dynamic> providers = {};
  bool loadingProviders = true;

  // ✅ CONTROLLER
  TextEditingController reviewController = TextEditingController();

  int? userId;

  @override
  void initState() {
    super.initState();
    loadProviders();
    loadUserId(); // ✅ LOAD USER ID
  }

  Future<void> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt("user_id");
  }

  Future<void> loadProviders() async {
    try {
      final data =
          await TMDBService().getWatchProviders(widget.movieId);

      setState(() {
        providers = data;
        loadingProviders = false;
      });
    } catch (e) {
      setState(() => loadingProviders = false);
    }
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      initialDate: watchedDate,
    );

    if (d != null) {
      setState(() => watchedDate = d);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat("EEEE, d MMMM, yyyy").format(watchedDate);

    return Scaffold(
      backgroundColor: const Color(0xFF1C1F23),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1F23),
        title: const Text("I Watched"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.white),

            // ✅🔥 MAIN FIX HERE
            onPressed: () async {
              if (userId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("User not logged in")),
                );
                return;
              }

              if (rating == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please give rating")),
                );
                return;
              }

              final reviewText = reviewController.text;

              try {
                final success = await ApiService.addReview(
                  userId: userId!,
                  movieId: widget.movieId,
                  rating: rating,
                  reviewText: reviewText,
                );

                print("REVIEW SENT: $success");

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Review added")),
                  );

                  Navigator.pop(context, true); // ✅ go back
                }
              } catch (e) {
                print("Review error: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Failed to save review")),
                );
              }
            },
          )
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          /// MOVIE POSTER + TITLE
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: widget.posterUrl != null
                    ? Image.network(
                        widget.posterUrl!,
                        width: 70,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 70,
                        height: 100,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  "${widget.title} (${widget.year})",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              )
            ],
          ),

          const SizedBox(height: 20),

          /// DATE
          Row(
            children: [
              Text(
                "Date  $formattedDate",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white38),
                onPressed: pickDate,
              )
            ],
          ),

          const SizedBox(height: 10),

          /// RATING
          Row(
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => rating = i + 1.0),
                icon: Icon(
                  Icons.star,
                  size: 34,
                  color: (i < rating) ? Colors.blue : Colors.white24,
                ),
              ),
            ),
          ),

          /// LIKE BUTTON
          IconButton(
            icon: Icon(
              liked ? Icons.favorite : Icons.favorite_border,
              size: 32,
              color: liked ? Colors.red : Colors.white38,
            ),
            onPressed: () => setState(() => liked = !liked),
          ),

          const SizedBox(height: 20),

          /// REVIEW ✅ FIXED
          TextField(
            controller: reviewController, // ✅ IMPORTANT
            maxLines: 5,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Add review...",
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF2A2E33),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 25),

          /// WATCHLIST
          const Text("Watchlist",
              style: TextStyle(color: Colors.white70, fontSize: 17)),
          SwitchListTile(
            activeColor: Colors.blue,
            value: inWatchlist,
            onChanged: (v) => setState(() => inWatchlist = v),
            title: const Text("Add to Watchlist",
                style: TextStyle(color: Colors.white)),
          ),

          const SizedBox(height: 20),

          /// WHERE TO WATCH
          const Text("Where to Watch",
              style: TextStyle(color: Colors.white70, fontSize: 17)),
          const SizedBox(height: 10),

          if (loadingProviders)
            const Center(
                child: CircularProgressIndicator(color: Colors.blue))
          else if (providers.isEmpty)
            const Text("No streaming options available.",
                style: TextStyle(color: Colors.white54))
          else
            buildProvidersList(),
        ],
      ),
    );
  }

  Widget buildProvidersList() {
    final flatrate = providers["flatrate"] ?? [];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: flatrate.map<Widget>((item) {
        final logo = "https://image.tmdb.org/t/p/w200${item['logo_path']}";
        final name = item["provider_name"];

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                logo,
                width: 55,
                height: 55,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}