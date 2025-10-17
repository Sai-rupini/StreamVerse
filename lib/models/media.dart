// lib/models/media.dart
import 'package:movie/services/genre_mapper.dart';
class Media {
  final int id; // ⭐️ NEW: Required for API calls
  final String mediaType;
  final String title;
  final String imagePath;
  final String plot;
  final String imdbRating;
  final List<String> genres; // Note: Will be genre IDs as strings for now
  final List<String> actors;
  final List<String> directors;
  final String? trailerUrl;
  
  static const String _imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  String get fullImageUrl {
    if (imagePath.startsWith('/')) {
      return '$_imageBaseUrl$imagePath';
    }
    return '$_imageBaseUrl/$imagePath';
  }

  String? get fullTrailerUrl {
    if (trailerUrl != null && trailerUrl!.isNotEmpty) {
      return 'https://www.youtube.com/watch?v=$trailerUrl';
    }
    return null;
  }
  
  
  const Media({
    required this.id, // ⭐️ Add to constructor
    required this.mediaType,
    required this.title,
    required this.imagePath,
    required this.plot,
    required this.imdbRating,
    required this.genres,
    required this.actors,
    required this.directors,
    this.trailerUrl,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    final String type = json['media_type'] as String? ?? (json.containsKey('first_air_date') ? 'tv' : 'movie');
    // ⭐️ FIX 1: Handle TV shows (which use 'name') and Movies (which use 'title').
    final String mediaTitle = json['title'] as String? ?? json['name'] as String? ?? 'N/A Title';

    // ⭐️ FIX 2: TMDB returns genre IDs (numbers), not genre names.
    // We map the numbers to strings for the List<String> field.
     final List<int> genreIds = (json['genre_ids'] as List<dynamic>?)
        ?.whereType<int>() // Ensure only integers are processed
        .toList() ?? [];

    // ⭐️ CRITICAL: Map the IDs to their corresponding names
    final List<String> genreNames = GenreMapper.mapIdsToNames(genreIds);


    return Media(
      id: json['id'] as int, // ⭐️ Extract the ID
      mediaType: type,
      title: mediaTitle,
      
      // 'poster_path' is correct for TMDB
      imagePath: json['poster_path'] as String? ?? '', 
      
      // 'overview' is correct for TMDB plot/summary
      plot: json['overview'] as String? ?? 'No plot available.',
      
      // 'vote_average' is correct. Ensure it handles null/double and converts to one decimal place.
      imdbRating: json['vote_average']?.toStringAsFixed(1) ?? 'N/A', 
      
      // Use the converted genre IDs
      genres: genreNames, 
      
      // These keys require secondary API calls (e.g., /movie/{id}/credits), so leave them empty.
      actors: const [], 
      directors: const [], 
      
      // 'trailer_link' is hypothetical and not standard for TMDB list responses, 
      // so it's safe to default to null.
      trailerUrl: json['trailer_link'] as String?, 
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Media && other.title == title);

  @override
  int get hashCode => title.hashCode;
}