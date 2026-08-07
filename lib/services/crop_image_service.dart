import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches a real photo for a crop from Wikipedia's public REST API
/// (no API key required, images are public domain or CC-licensed).
/// Results are cached in memory for the app session so the same crop
/// isn't re-fetched every time its card scrolls back into view.
class CropImageService {
  static final Map<String, String?> _cache = {};

  /// [wikiTitle] should be the crop's canonical Wikipedia article title
  /// (e.g. "Tomato", "Eggplant") — see CropOption.wikiImageTitle.
  /// Returns null if no image is found or the request fails, so callers
  /// can fall back to a placeholder icon.
  static Future<String?> fetchImageUrl(String wikiTitle) async {
    if (_cache.containsKey(wikiTitle)) return _cache[wikiTitle];

    try {
      final encodedTitle = Uri.encodeComponent(wikiTitle.replaceAll(' ', '_'));
      final response = await http
          .get(Uri.parse("https://en.wikipedia.org/api/rest_v1/page/summary/$encodedTitle"))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        _cache[wikiTitle] = null;
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final imageUrl = data["thumbnail"]?["source"] as String?;
      _cache[wikiTitle] = imageUrl;
      return imageUrl;
    } catch (_) {
      _cache[wikiTitle] = null;
      return null;
    }
  }
}
