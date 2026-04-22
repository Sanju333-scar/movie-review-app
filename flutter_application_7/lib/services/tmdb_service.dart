import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tmdb_movie_model.dart';

class TMDBService {
static const String _apiKey = '1c276cf829ca49b3f730a6bbb4c48635';
  static const String _base = 'https://api.themoviedb.org/3'; 
  static const String _imageBase = 'https://image.tmdb.org/t/p/w500';

  /// 🔹 Helper function to convert TMDB JSON to TMDBMovie safely
  TMDBMovie _parseMovie(Map<String, dynamic> json) {
    return TMDBMovie(
      id: json['id'],
      title: json['title'] ?? json['name'] ?? '',
      overview: json['overview'],
      posterPath: json['poster_path'] != null ? '$_imageBase${json['poster_path']}' : null,
      backdropPath: json['backdrop_path'] != null ? '$_imageBase${json['backdrop_path']}' : null,
      releaseDate: json['release_date'],
      voteAverage: (json['vote_average'] != null)
          ? (json['vote_average'] as num).toDouble()
          : null,
    );
  }

  // 🔸 Popular
  Future<List<TMDBMovie>> getPopularMovies({int page = 1}) async {
    final url = Uri.parse('$_base/movie/popular?api_key=$_apiKey&language=en-US&page=$page');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final map = json.decode(res.body);
      final List results = map['results'] ?? [];
      return results.map((e) => _parseMovie(e)).toList();
    } else {
      throw Exception('TMDB getPopularMovies failed: ${res.statusCode}');
    }
  }

  // 🔸 Top Rated
  Future<List<TMDBMovie>> getTopRatedMovies({int page = 1}) async {
    final url = Uri.parse('$_base/movie/top_rated?api_key=$_apiKey&language=en-US&page=$page');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final map = json.decode(res.body);
      final List results = map['results'] ?? [];
      return results.map((e) => _parseMovie(e)).toList();
    } else {
      throw Exception('TMDB getTopRatedMovies failed: ${res.statusCode}');
    }
  }

  // 🔸 Upcoming
  Future<List<TMDBMovie>> getUpcomingMovies({int page = 1}) async {
    final url = Uri.parse('$_base/movie/upcoming?api_key=$_apiKey&language=en-US&page=$page');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final map = json.decode(res.body);
      final List results = map['results'] ?? [];
      return results.map((e) => _parseMovie(e)).toList();
    } else {
      throw Exception('TMDB getUpcomingMovies failed: ${res.statusCode}');
    }
  }

  // 🔸 Search
  Future<List<TMDBMovie>> searchMovies(String query, {int page = 1}) async {
    final url = Uri.parse(
      '$_base/search/movie?api_key=$_apiKey&language=en-US&query=${Uri.encodeQueryComponent(query)}&page=$page&include_adult=false',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final map = json.decode(res.body);
      final List results = map['results'] ?? [];
      return results.map((e) => _parseMovie(e)).toList();
    } else {
      throw Exception('TMDB searchMovies failed: ${res.statusCode}');
    }
  }

  // 🔸 Movie details (includes credits, providers, videos)
  Future<Map<String, dynamic>> getMovieDetails(int movieId) async {
    final url = Uri.parse(
      '$_base/movie/$movieId?api_key=$_apiKey&append_to_response=credits,release_dates,watch/providers,videos',
    );
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('TMDB getMovieDetails failed: ${res.statusCode}');
    }
  }

  // 🔸 Credits only
  Future<Map<String, dynamic>> getCredits(int movieId) async {
    final url = Uri.parse('$_base/movie/$movieId/credits?api_key=$_apiKey');
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return json.decode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('TMDB getCredits failed: ${res.statusCode}');
    }
  }
  // ----------------------------------------------------------
  // ⭐ CAST / CREW SEARCH (People)
  // ----------------------------------------------------------
  Future<List<dynamic>> searchPeople(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      '$_base/search/person?api_key=$_apiKey&query=${Uri.encodeQueryComponent(query)}',
    );

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['results'] ?? [];
    }

    return [];
  }

  // ----------------------------------------------------------
  // ⭐ STUDIO SEARCH (Companies)
  // ----------------------------------------------------------
  Future<List<dynamic>> searchCompanies(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      '$_base/search/company?api_key=$_apiKey&query=${Uri.encodeQueryComponent(query)}',
    );

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['results'] ?? [];
    }

    return [];
  }

  // ----------------------------------------------------------
  // ⭐ COMBINED SEARCH (People + Companies)
  // ----------------------------------------------------------
  Future<List<dynamic>> searchPeopleAndCompanies(String query) async {
    final people = await searchPeople(query);
    final companies = await searchCompanies(query);

    final peopleMapped = people.map((p) {
      p["media_type"] = "person";
      return p;
    }).toList();

    final companiesMapped = companies.map((c) {
      c["media_type"] = "company";
      return c;
    }).toList();

    return [...peopleMapped, ...companiesMapped];
  }

  // ----------------------------------------------------------
  // ⭐ PERSON DETAILS
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getPersonDetails(int id) async {
    final url = Uri.parse(
      '$_base/person/$id?api_key=$_apiKey&language=en-US',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return {};
  }

  // ----------------------------------------------------------
  // ⭐ PERSON CREDITS
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getPersonCredits(int personId) async {
    final url = Uri.parse(
      '$_base/person/$personId/combined_credits?api_key=$_apiKey',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      return {"cast": [], "crew": []};
    }

    final data = jsonDecode(response.body);

    return {
      "cast": data['cast'] ?? [],
      "crew": data['crew'] ?? [],
    };
  }

  // ----------------------------------------------------------
  // ⭐ PERSON COMBINED CREDITS
  // ----------------------------------------------------------
  Future<List<dynamic>> getPersonCombinedCredits(int id) async {
    final url = Uri.parse(
      '$_base/person/$id/combined_credits?api_key=$_apiKey&language=en-US',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final cast = data['cast'] ?? [];
      final crew = data['crew'] ?? [];

      return [...cast, ...crew];
    }

    return [];
  }

  // ----------------------------------------------------------
  // ⭐ BUILD PERSON DESCRIPTION
  // ----------------------------------------------------------
  Future<String> buildPersonDescription(int personId) async {
    final credits = await getPersonCredits(personId);

    final cast = credits["cast"];
    final crew = credits["crew"];

    if (cast.isNotEmpty) {
      final titles =
          cast.take(3).map((m) => m['title'] ?? m['name']).toList();
      return "Acting in ${cast.length} films including ${titles.join(", ")}";
    }

    if (crew.isNotEmpty) {
      final job = crew.first["job"] ?? "Crew";
      final titles =
          crew.take(3).map((m) => m['title'] ?? m['name']).toList();
      return "$job in ${crew.length} productions including ${titles.join(", ")}";
    }

    return "No credits available";
  }

  // ----------------------------------------------------------
  // ⭐ WATCH PROVIDERS
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getWatchProviders(int movieId) async {
    final url = Uri.parse(
      '$_base/movie/$movieId/watch/providers?api_key=$_apiKey',
    );

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return data['results']['IN'] ?? {};
    }

    throw Exception("Failed to load watch providers");
  }



  // ----------------------------------------------------------
  // ⭐ GET GENRES
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getGenres() async {
    final url = Uri.parse('$_base/genre/movie/list?api_key=$_apiKey');

    final res = await http.get(url);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      return List<Map<String, dynamic>>.from(data['genres']);
    }

    return [];
  }

  // ----------------------------------------------------------
  // ⭐ GET COUNTRIES
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getCountries() async {
    final url =
        Uri.parse('$_base/configuration/countries?api_key=$_apiKey');

    final res = await http.get(url);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }

    return [];
  }

  // ----------------------------------------------------------
  // ⭐ GET LANGUAGES
  // ----------------------------------------------------------
  Future<List<Map<String, dynamic>>> getLanguages() async {
    final url =
        Uri.parse('$_base/configuration/languages?api_key=$_apiKey');

    final res = await http.get(url);
    if (res.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(res.body));
    }

    return [];
  }

  // ----------------------------------------------------------
  // ⭐ MOVIES BY GENRE
  // ----------------------------------------------------------
  Future<List<TMDBMovie>> getMoviesByGenre(int genreId) async {
    final url =
        '$_base/discover/movie?api_key=$_apiKey&with_genres=$genreId&sort_by=popularity.desc';

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    return (data["results"] as List)
        .map((m) => _parseMovie(m))
        .toList();
  }

  // ----------------------------------------------------------
  // ⭐ MOVIES BY COUNTRY
  // ----------------------------------------------------------
  Future<List<TMDBMovie>> getMoviesByCountry(String countryCode, {int page = 1}) async {
  final url =
      '$_base/discover/movie?api_key=$_apiKey&region=$countryCode&sort_by=popularity.desc&page=$page';

  final res = await http.get(Uri.parse(url));
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data["results"] as List).map((m) => _parseMovie(m)).toList();
  } else {
    throw Exception('Failed to load movies by country');
  }
}


  // ----------------------------------------------------------
  // ⭐ MOVIES BY LANGUAGE
  // ----------------------------------------------------------
  Future<List<TMDBMovie>> getMoviesByLanguage(String langCode) async {
    final url =
        '$_base/discover/movie?api_key=$_apiKey&with_original_language=$langCode&sort_by=popularity.desc';

    final res = await http.get(Uri.parse(url));
    final data = jsonDecode(res.body);

    return (data["results"] as List)
        .map((m) => _parseMovie(m))
        .toList();
  }

// ----------------------------
// Movies by Filter (Year / Genre / Country / Language)
// ----------------------------
Future<List<TMDBMovie>> getMoviesByFilter({
  required String type,
  required String value,
  int page = 1,
}) async {
  String url = '';

  if (type == "year") {
    url =
        '$_base/discover/movie?api_key=$_apiKey&primary_release_date.gte=$value-01-01&primary_release_date.lte=$value-12-31&sort_by=popularity.desc&page=$page';
  }

  if (type == "genre") {
    url =
        '$_base/discover/movie?api_key=$_apiKey&with_genres=$value&sort_by=popularity.desc&page=$page';
  }

  if (type == "country") {
    url =
        '$_base/discover/movie?api_key=$_apiKey&with_origin_country=$value&sort_by=popularity.desc&page=$page';
  }

  if (type == "language") {
    url =
        '$_base/discover/movie?api_key=$_apiKey&with_original_language=$value&sort_by=popularity.desc&page=$page';
  }

  final res = await http.get(Uri.parse(url));
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data["results"] as List)
        .map((m) => _parseMovie(m))
        .toList();
  } else {
    throw Exception("Failed to load movies");
  }
}
// ----------------------------------------------------------
// ⭐ MOVIES BY RELEASE DATE (for YearPage, etc.)
// ----------------------------------------------------------
Future<List<TMDBMovie>> getMoviesByReleaseDate({
  required String fromDate,  // e.g., "2023-01-01"
  required String toDate,    // e.g., "2023-12-31"
  int page = 1,
  String sortBy = 'popularity.desc',
}) async {
  final url =
      '$_base/discover/movie?api_key=$_apiKey&primary_release_date.gte=$fromDate&primary_release_date.lte=$toDate&sort_by=$sortBy&page=$page';

  final res = await http.get(Uri.parse(url));
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return (data["results"] as List)
        .map((m) => _parseMovie(m))
        .toList();
  } else {
    throw Exception("Failed to load movies by release date");
  }
}
}
