// lib/services/genre_mapper.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class GenreMapper {
  // A static map to store the ID -> Name mapping once loaded.
  static Map<int, String> _genreMap = {};
  
  // Flag to check if the map has been loaded.
  static bool get isLoaded => _genreMap.isNotEmpty;

  // TMDB endpoint to get the list of Movie genres (TV has a separate list)
  static const String _movieGenreUrl = 'https://api.themoviedb.org/3/genre/movie/list';

  // Your TMDB API Key
  static const String _apiKey = '74e69f631d763d7d38ef69ce67d749b9'; 

  // ⭐️ CRITICAL METHOD: Fetches and builds the ID -> Name map
  static Future<void> loadGenreMap() async {
    if (isLoaded) return; // Avoid re-fetching

    try {
      final url = Uri.parse('$_movieGenreUrl?api_key=$_apiKey');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List genres = jsonResponse['genres'] as List;

        // Build the map: {28: 'Action', 12: 'Adventure', ...}
        _genreMap = Map.fromIterable(
          genres,
          key: (item) => item['id'] as int,
          value: (item) => item['name'] as String,
        );
        print('✅ Genre Map loaded successfully. Count: ${_genreMap.length}');

      } else {
        print('❌ Failed to load genre list. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('🛑 Network error while loading genres: $e');
    }
  }

  // ⭐️ MAPPING METHOD: Converts a list of IDs to a list of Names
  static List<String> mapIdsToNames(List<int> ids) {
    if (!isLoaded) {
      // Should not happen if loadGenreMap is called first, but good practice.
      return ids.map((id) => 'ID: $id').toList();
    }
    
    return ids.map((id) => _genreMap[id] ?? 'Unknown').toList();
  }
}