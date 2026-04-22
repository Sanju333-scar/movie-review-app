import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class BackendService {
  static const String baseUrl = Config.baseUrl;

  // CREATE LIST
  Future<int> createList({
    required String token,
    required String name,
    required String description,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/lists"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "name": name,
        "description": description,
      }),
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body)["list_id"];
    } else {
      throw Exception(res.body);
    }
  }

  // ADD MOVIE TO LIST
  Future<void> addMovieToList({
    required String token,
    required int listId,
    required int movieTmdbId,
  }) async {
    final res = await http.post(
      Uri.parse("$baseUrl/lists/$listId/movies/$movieTmdbId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode != 201) {
      throw Exception(res.body);
    }
  }

  // ✅ FETCH USER LISTS (with movies)
  Future<List<dynamic>> getUserLists(String token) async {
    final res = await http.get(
      Uri.parse("$baseUrl/lists"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception(res.body);
    }
  }
}
