import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIHelper {
  // Your Gemini API Key from Google AI Studio
  static final String _apiKey =
      dotenv.env['GEMINI_API_KEY'] ?? '';

  /// Returns a short corrected version (grammar/spelling) of user input
  static Future<String> getSuggestion(String prompt) async {
    final model = "gemini-2.5-flash"; // Free-tier Gemini
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent",
    );

    // Here we tell Gemini explicitly:
    // Keep it short
    // Correct grammar and spelling
    // Give best concise suggestion for chat
    final instruction =
        """
You are an intelligent assistant. 
Correct grammar and spelling in the following text and give the best concise suggestion in 2 lines only. 
Do not make it long. Keep it ready to send as a chat message.

Text: "$prompt"
""";

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": _apiKey,
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": instruction},
            ],
          },
        ],
      }),
    );

    print("Gemini STATUS: ${response.statusCode}");
    print("Gemini BODY: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception("Gemini failed: ${response.body}");
    }

    final data = jsonDecode(response.body);

    // Extract the generated text safely
    final candidates = data["candidates"] as List<dynamic>?;
    if (candidates != null && candidates.isNotEmpty) {
      final content = candidates[0]["content"]["parts"] as List<dynamic>;
      return content.map((p) => p["text"] ?? "").join();
    }

    throw Exception("Gemini returned no text");
  }
}
