import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class ActivityService {
  static Future<Map<String, dynamic>> fetchUserActivity(int userId) async {
    final url = Uri.parse('${Config.baseUrl}/activity/user/$userId');

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load activity");
    }
  }
}
