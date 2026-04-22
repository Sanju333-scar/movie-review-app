import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recommendation_model.dart';

class RecommendationService {
  final String baseUrl = "http://10.59.243.252:8000"; 
  // 🔥 If physical phone → use your PC IP

  Future<List<Recommendation>> fetchRecommendations(int userId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/recommendations/$userId"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      List recs = data["recommendations"];

      return recs.map((e) => Recommendation.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load recommendations");
    }
  }

  // 🔹 Add to seed
// 🔹 Add to seed (CORRECT VERSION)
Future<void> addToSeed(int userId, int tmdbId) async {
  final response = await http.post(
    Uri.parse("$baseUrl/seed/add"),
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "user_id": userId,
      "tmdb_id": tmdbId,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to add to seed");
  }
}
}