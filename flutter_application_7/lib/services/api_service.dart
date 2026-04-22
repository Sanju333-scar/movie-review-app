import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_7/config.dart';

class ApiService {
  static final String baseUrl = Config.baseUrl;

  // ============================================================
  // ✅ ADD MOVIE TO BACKEND
  // ============================================================
  static Future<bool> addMovie({
    required int tmdbId,
    required String title,
    required String overview,
    required String releaseDate,
    required String posterPath,
    required double popularity,
    required List<String> genres,
  }) async {
    final url = Uri.parse('$baseUrl/movies/');

    final body = {
      "tmdb_id": tmdbId,
      "title": title,
      "overview": overview,
      "release_date": releaseDate,
      "poster_path": posterPath,
      "tmdb_popularity": popularity,
      "genres": genres.map((g) => {"genre": g}).toList(),
    };

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("ADD MOVIE RESPONSE: ${res.body}");

    return res.statusCode == 200 || res.statusCode == 201;
  }

  // ============================================================
  // ✅ SIGNUP
  // ============================================================
  static Future<bool> signup(String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/signup');

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      }),
    );

    return res.statusCode == 200;
  }

  // ============================================================
  // ✅ LOGIN + SAVE USER ID
  // ============================================================
  static Future<bool> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final prefs = await SharedPreferences.getInstance();

      await prefs.setInt('user_id', data['user_id']);
      await prefs.setString('email', data['email']);

      return true;
    }

    return false;
  }

  // ============================================================
  // ✅ FORGOT PASSWORD
  // ============================================================
  static Future<bool> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/forgot-password');

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    return res.statusCode == 200;
  }

  // ============================================================
  // ✅ RESET PASSWORD
  // ============================================================
  static Future<bool> resetPassword(String email, String newPassword) async {
    final url = Uri.parse('$baseUrl/reset-password');

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "new_password": newPassword,
      }),
    );

    return res.statusCode == 200;
  }

  // ============================================================
  // ✅ ADD REVIEW
  // ============================================================
  static Future<bool> addReview({
    required int userId,
    required int movieId,
    required double rating,
    String? reviewText,
  }) async {
    final url = Uri.parse('$baseUrl/reviews');

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "movie_id": movieId,
        "rating": rating,
        "review_text": reviewText,
      }),
    );

    print("ADD REVIEW RESPONSE: ${res.body}");

    return res.statusCode == 200 || res.statusCode == 201;
  }

  // ============================================================
  // ✅ LOG EVENT (like, rate, view, watchlist)
  // ============================================================
  static Future<bool> logEvent({
    required int userId,
    required int tmdbId,
    required String eventType,
    double? value,
  }) async {
    final url = Uri.parse('$baseUrl/events');

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "tmdb_id": tmdbId,
        "event_type": eventType,
        "value": value,
      }),
    );

    print("EVENT RESPONSE: ${res.body}");

    return res.statusCode == 200 || res.statusCode == 201;
  }

  // ============================================================
  // ✅ GET USER ID (Shared Pref)
  // ============================================================
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // ============================================================
  // ✅ FETCH REVIEWS FOR MOVIE
  // ============================================================
  static Future<List<dynamic>> getReviews(int movieId) async {
    final url = Uri.parse('$baseUrl/reviews/$movieId');

    final res = await http.get(url);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      print("❌ Failed to fetch reviews: ${res.body}");
      return [];
    }
  }

  // ============================================================
  // ✅ FETCH USER ACTIVITY (likes, watchlist, ratings, reviews)
  // ============================================================
static Future<Map<String, dynamic>> getUserMovieActivity(int userId, int movieId) async {
  final url = Uri.parse("$baseUrl/events/user/$userId/movie/$movieId");

  final res = await http.get(url);

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  } else {
    throw Exception("Failed to load activity: ${res.body}");
  }
}


  // ============================================================
  // ✅ FETCH LIKES FOR A MOVIE
  // ============================================================
  static Future<List<dynamic>> getLikes(int movieId) async {
    final url = Uri.parse('$baseUrl/events/movie/$movieId/likes');

    final res = await http.get(url);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return [];
  }

  // ============================================================
  // ✅ FETCH RATINGS FOR A MOVIE
  // ============================================================
  static Future<List<dynamic>> getRatings(int movieId) async {
    final url = Uri.parse('$baseUrl/events/movie/$movieId/ratings');

    final res = await http.get(url);

    if (res.statusCode == 200) return jsonDecode(res.body);

    return [];
  }

  // ============================================================
  // ✅ FETCH WATCHLIST FOR USER
  // ============================================================
  static Future<List<dynamic>> getWatchlist(int userId) async {
    final url = Uri.parse('$baseUrl/events/$userId/watchlist');

    final res = await http.get(url);

    if (res.statusCode == 200) return jsonDecode(res.body);

    return [];
  }

  static Future<List<dynamic>> getMovieReviews(int movieId) async {
  final url = Uri.parse("$baseUrl/reviews/movie/$movieId");

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data["reviews"]; // IMPORTANT
  } else {
    throw Exception("Failed to load reviews");
  }
}

//

static Future<List<dynamic>> getAIRecommendations(int movieId) async {
  final res = await http.get(
    Uri.parse("$baseUrl/ai/recommend/$movieId"),
  );

  print("AI RESPONSE STATUS: ${res.statusCode}");
  print("AI RESPONSE BODY: ${res.body}");

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);

    // Ensure it's a List
    if (data is List) {
      return data;
    } else {
      print("❌ Not a list: $data");
      return [];
    }
  } else {
    print("❌ API ERROR: ${res.body}");
    return [];
  }
}
static Future<List<dynamic>> getSimilarMovies(int movieId) async {
  final apiKey = "1c276cf829ca49b3f730a6bbb4c48635"; // your TMDB key

  final url = Uri.parse(
    "https://api.themoviedb.org/3/movie/$movieId/similar?api_key=$apiKey",
  );

  final res = await http.get(url);

  print("SIMILAR STATUS: ${res.statusCode}");
  print("SIMILAR BODY: ${res.body}");

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return data["results"]; // returns list of movies
  } else {
    return [];
  }
}
  
}

