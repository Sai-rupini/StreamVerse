// lib/services/media_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:movie/models/media.dart';
import 'package:movie/services/genre_mapper.dart'; // Assume this is needed for genre mapping

// ⭐️ NOTE: Replace 'YOUR_API_KEY' and 'YOUR_ACCESS_TOKEN' with your actual keys.
const String _tmdbApiKey = '74e69f631d763d7d38ef69ce67d749b9'; 
const String _tmdbBaseUrl = 'https://api.themoviedb.org/3';
const String _tmdbImageUrl = 'https://image.tmdb.org/t/p/w500'; // Base URL for images

class MediaService {
    
    // ⭐ NEW METHOD: Fetches trending media (daily)
    Future<List<Media>> fetchTrendingMedia() async {
        final Uri uri = Uri.parse('$_tmdbBaseUrl/trending/all/day?api_key=$_tmdbApiKey');
        return _fetchMediaList(uri);
    }

    // ⭐ NEW METHOD: Fetches a list of media by type (e.g., 'movie', 'tv')
    Future<List<Media>> fetchMediaList(String mediaType) async {
        // You can change the endpoint (e.g., /popular, /top_rated)
        final Uri uri = Uri.parse('$_tmdbBaseUrl/$mediaType/popular?api_key=$_tmdbApiKey');
        return _fetchMediaList(uri);
    }
    
    // ⭐ HELPER METHOD: Handles the API call and JSON parsing
    Future<List<Media>> _fetchMediaList(Uri uri) async {
        try {
            final response = await http.get(uri);

            if (response.statusCode == 200) {
                final Map<String, dynamic> json = jsonDecode(response.body);
                final List<dynamic> results = json['results'] ?? [];

                return results.map((item) {
                    // Extract ID and Media Type
                    final int id = item['id'] as int;
                    // TMDB uses 'media_type' in trending results, otherwise infer from URL parameter
                    final String mediaType = item['media_type'] as String? ?? (uri.pathSegments.contains('movie') ? 'movie' : 'tv');
                    
                    // Use GenreMapper to convert IDs to names
                    final List<int> genreIds = List<int>.from(item['genre_ids'] ?? []);
                    final List<String> genres = GenreMapper.mapIdsToNames(genreIds);

                    // Determine title based on media type
                    final String title = mediaType == 'movie' 
                        ? item['title'] as String? ?? 'Untitled Movie'
                        : item['name'] as String? ?? 'Untitled Show';

                    return Media(
                        id: id,
                        mediaType: mediaType,
                        title: title,
                        // Construct the full image URL
                        imagePath: item['poster_path'] != null ? '$_tmdbImageUrl${item['poster_path']}' : '',
                        plot: item['overview'] as String? ?? 'No plot available.',
                        // Format the rating to one decimal place
                        imdbRating: (item['vote_average'] as num?)?.toStringAsFixed(1) ?? 'N/A',
                        genres: genres,
                        // Details like actors/directors are fetched later in fetchMediaDetails
                        actors: const [], 
                        directors: const [],
                    );
                }).toList();
            } else {
                print('Failed to load media list. Status: ${response.statusCode}');
                return [];
            }
        } catch (e) {
            print('Error fetching media list: $e');
            return [];
        }
    }


    // ⭐️ EXISTING METHOD: Fetch Details (including Trailer/Cast/Crew) for a single Media item
    Future<Media> fetchMediaDetails(Media media) async {
        // The details endpoint is /movie/{id} or /tv/{id}
        final String url = '$_tmdbBaseUrl/${media.mediaType}/${media.id}';

        // ⭐️ Use append_to_response to get credits (actors/directors) and videos (trailers) in one request
        final Uri uri = Uri.parse('$url?api_key=$_tmdbApiKey&append_to_response=credits,videos');

        try {
            final response = await http.get(uri);

            if (response.statusCode == 200) {
                final Map<String, dynamic> json = jsonDecode(response.body);

                // --- Extract Trailer Key ---
                final List<dynamic>? videos = json['videos']?['results'];
                String? trailerKey;
                if (videos != null && videos.isNotEmpty) {
                    // Find the first official trailer that is hosted on YouTube
                    final trailer = videos.firstWhere(
                        (v) => v['site'] == 'YouTube' && (v['type'] == 'Trailer' || v['type'] == 'Teaser'),
                        orElse: () => null,
                    );
                    trailerKey = trailer?['key'] as String?;
                }

                // --- Extract Cast & Crew ---
                final List<dynamic>? cast = json['credits']?['cast'];
                final List<dynamic>? crew = json['credits']?['crew'];

                final List<String> actors = (cast)
                    ?.take(5) // Get top 5 actors
                    .map((c) => c['name'].toString())
                    .toList() ?? [];

                final List<String> directors = (crew)
                    ?.where((c) => c['job'] == 'Director')
                    .take(3) // Get top 3 directors
                    .map((c) => c['name'].toString())
                    .toList() ?? [];
                
                // Return a new Media object with all the details filled in
                return Media(
                    id: media.id,
                    mediaType: media.mediaType,
                    title: media.title,
                    imagePath: media.imagePath,
                    plot: media.plot,
                    imdbRating: media.imdbRating,
                    genres: media.genres,
                    actors: actors,
                    directors: directors,
                    trailerUrl: trailerKey, // ⭐️ Pass the extracted YouTube key here
                );
            } else {
                throw Exception('Failed to load media details. Status: ${response.statusCode}');
            }
        } catch (e) {
            print('Error fetching media details: $e');
            // On failure, return the original Media object without details
            return media; 
        }
    }
}