import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost:8000";

  static Future<Map<String, dynamic>> predict({
    required int startDelay,
    required int lastMinuteRush,
    required int focusRating,
    required int distractions,
    required int coffee,
    required int qualityScore,
    required int stressLevel,
    required int complexityLow,
    required int complexityMedium,
  }) async {

    final response = await http.post(
      Uri.parse("$baseUrl/predict"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "task_complexity_low": complexityLow,
        "task_complexity_medium": complexityMedium,
        "start_delay_min": startDelay,
        "last_minute_rush": lastMinuteRush,
        "focus_rating": focusRating,
        "distractions_count": distractions,
        "coffee_intake_mg": coffee,
        "task_quality_score": qualityScore,
        "stress_level": stressLevel
      }),
    );

    return jsonDecode(response.body);
  }
}
