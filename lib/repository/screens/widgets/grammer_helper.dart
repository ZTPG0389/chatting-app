import 'dart:convert';
import 'package:http/http.dart' as http;

class GrammarHelper {
  /// Fix grammar & spelling using LanguageTool API
  static Future<String> fixText(String text) async {
    if (text.trim().isEmpty) return text;

    final url = Uri.parse('https://api.languagetool.org/v2/check');
    final response = await http.post(
      url,
      body: {
        'text': text,
        'language': 'en-US',
      },
    );

    if (response.statusCode != 200) return text;

    final data = jsonDecode(response.body);
    String corrected = text;

    // Apply all replacements from the API
    for (var match in data['matches'].reversed) {
      if (match['replacements'] != null && match['replacements'].isNotEmpty) {
        final replacement = match['replacements'][0]['value'];
        final offset = match['offset'];
        final length = match['length'];

        // Replace the wrong word/phrase with corrected one
        corrected = corrected.replaceRange(offset, offset + length, replacement);
      }
    }

    return corrected; // Return fully corrected text without changing capitalization manually
  }
}
