import 'package:http/http.dart' as http;
import '../config.dart';
import 'dart:convert';


class EventService {
  static Future<bool> sendEvent({
    required int userId,
    required int movieId,
    required String eventType,
    double? value,
    String? title,
    String? overview,
    String? posterPath,
    String? releaseDate,
    double? popularity,
  }) async {
    final url = Uri.parse("${Config.baseUrl}/events/add");

final Map<String, String> body = {
  "user_id": userId.toString(),
  "tmdb_id": movieId.toString(),
  "event_type": eventType,
};




    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),

    );

    return response.statusCode == 200;
  }

  static Future<bool> sendView(int userId, int movieId) {
    return sendEvent(
      userId: userId,
      movieId: movieId,
      eventType: "view",
    );
  }

  static Future<bool> sendLike(int userId, int movieId) {
    return sendEvent(
      userId: userId,
      movieId: movieId,
      eventType: "like",
    );
  }

  static Future<bool> sendRate(int userId, int movieId, double rating) {
    return sendEvent(
      userId: userId,
      movieId: movieId,
      eventType: "rate",
      value: rating,
    );
  }

  static Future<bool> sendReview({
    required int userId,
    required int movieId,
    required String reviewText,
    double? rating,
  }) {
    return sendEvent(
      userId: userId,
      movieId: movieId,
      eventType: "review",
      value: rating,
      overview: reviewText,
    );
  }
}
