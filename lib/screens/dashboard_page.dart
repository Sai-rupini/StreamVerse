import 'package:flutter/material.dart';
import 'package:movie/models/media.dart';
import 'package:movie/screens/detail_page.dart';
import 'package:movie/screens/search_page.dart';
import 'package:movie/screens/welcome_page.dart';
import 'package:movie/services/auth_service.dart';
import 'package:movie/services/media_service.dart';
import 'package:movie/widgets/highlight_section.dart';
import 'package:movie/widgets/media_row.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movie/services/genre_mapper.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _currentCategory = 'Trending Now';
  final Set<Media> _likedMedia = {};

  // State for API integration
  Map<String, List<Media>> _allMedia = {};
  bool _isLoading = true;
  final MediaService _mediaService = MediaService();

  late final ScrollController _scrollController;
  late AnimationController _animationController;
  final List<Animation<Offset>> _rowAnimations = [];

  // ⭐ REPLACED: Consolidates multiple service calls into one robust function
  Future<void> _fetchMedia() async {
    if (!GenreMapper.isLoaded) {
      await GenreMapper.loadGenreMap();
    }
    
    // Define the structure to hold all data
    final Map<String, List<Media>> fetchedData = {};

    try {
      // ⭐️ FIX: Explicitly call assumed helper methods in MediaService
      final trending = await _mediaService.fetchTrendingMedia();
      final movies = await _mediaService.fetchMediaList('movie'); 
      final tvShows = await _mediaService.fetchMediaList('tv');
      
      // Filter the 'Animation' genre from TV shows to represent 'Anime'
      final anime = tvShows.where((m) => m.genres.contains('Animation')).toList();
      
      fetchedData['Trending Now'] = trending;
      fetchedData['Movies'] = movies;
      fetchedData['TV Shows'] = tvShows;
      fetchedData['Anime'] = anime;

      setState(() {
        _allMedia = fetchedData;
        _isLoading = false;
      });

      _initializeAnimations();

      // Now load preferences, as _allMedia is populated
      await _loadLikedMedia();

    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // In a real app, you might show an error dialog
      print('Error fetching media: $e');
    }
  }

  void _initializeAnimations() {
    // Check if _allMedia is empty before animating (safer)
    if (_allMedia.isEmpty || _animationController.isAnimating) return;

    // Dispose old controller if it exists and is initialized
    if (this.mounted && this._animationController.isAnimating) {
        this._animationController.dispose();
    }
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _rowAnimations.clear();

    // Only animate the rows that are NOT the main highlight
    final categories = _allMedia.keys
        .where((key) => key != 'Trending Now' && key != 'Recommended') 
        .toList();

    for (int i = 0; i < categories.length; i++) {
      final animation = Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            i * (1.0 / categories.length),
            1.0,
            curve: Curves.easeOutCubic,
          ),
        ),
      );
      _rowAnimations.add(animation);
    }
    _animationController.forward();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Initialize controller defensively before _fetchMedia, 
    // though _initializeAnimations will correctly re-initialize it.
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fetchMedia();
  }

  @override
  void dispose() {
    // Check if animationController was initialized before disposing
    if (this.mounted) {
      _animationController.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _addLikedMedia(Media media) {
    setState(() {
      _likedMedia.add(media);
    });
    _saveLikedMedia();
  }

  Future<void> _saveLikedMedia() async {
    final prefs = await SharedPreferences.getInstance();
    // Assuming 'title' is a unique identifier for the Media object
    // ⭐️ FIX: Use media.id instead of title as it is more likely to be unique
    final likedIds = _likedMedia.map((media) => media.id.toString()).toList();
    await prefs.setStringList('liked_media_ids', likedIds);
  }

  Future<void> _loadLikedMedia() async {
    final prefs = await SharedPreferences.getInstance();
    // ⭐️ FIX: Load by ID
    final likedIds = prefs.getStringList('liked_media_ids')?.map((id) => int.tryParse(id)).whereType<int>().toList() ?? [];

    // Flatten all media content for searching
    final allContent = _allMedia.values.expand((list) => list).toList();

    setState(() {
      _likedMedia.clear();
      for (var id in likedIds) {
        final media = allContent.firstWhere(
          (m) => m.id == id,
          // Fallback Media instance for orElse:
          orElse: () => const Media(
            id: -1, 
            mediaType: 'movie',
            title: '',
            imagePath: '',
            plot: '',
            imdbRating: '',
            genres: [],
            actors: [],
            directors: [],
          ),
        );
        // Only add media if found and valid (ID is not -1)
        if (media.id != -1) { 
          _likedMedia.add(media);
        }
      }
    });
  }

  List<Media> _getRecommendedMedia() {
    if (_likedMedia.isEmpty) {
      return [];
    }
    Set<String> likedGenres = {};
    for (var media in _likedMedia) {
      likedGenres.addAll(media.genres);
    }
    final allContent = _allMedia.values.expand((list) => list).toList();
    final recommendations = allContent.where((media) {
      bool hasMatchingGenre = media.genres.any((genre) => likedGenres.contains(genre));
      // ⭐️ FIX: Check by ID/mediaType for accurate comparison
      bool isNotLiked = !_likedMedia.any((liked) => liked.id == media.id && liked.mediaType == media.mediaType); 
      return hasMatchingGenre && isNotLiked;
    }).toList();
    
    // Return a maximum of 20 recommendations, shuffled
    recommendations.shuffle();
    return recommendations.take(20).toList();
  }

  void _showCategoriesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text('Select a Category', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Genres', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: ['Action', 'Adventure', 'Sci-Fi', 'Horror', 'Drama', 'Fantasy', 'Crime', 'Thriller', 'Biography', 'History']
                      .map((genre) => ActionChip(
                            label: Text(genre, style: const TextStyle(color: Colors.white)),
                            backgroundColor: Colors.red.withOpacity(0.5),
                            onPressed: () {
                              _filterByCategory(genre);
                              Navigator.of(context).pop();
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                const Text('Languages', style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: ['English', 'German', 'Japanese', 'Hindi']
                      .map((language) => ActionChip(
                            label: Text(language, style: const TextStyle(color: Colors.white)),
                            backgroundColor: Colors.blue.withOpacity(0.5),
                            onPressed: () {
                              _filterByCategory(language);
                              Navigator.of(context).pop();
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _filterByCategory(String category) {
    setState(() {
      _currentCategory = category;
    });
  }

  List<Media> _getDisplayedMedia(String category) {
    if (category == 'Recommended') {
      return _getRecommendedMedia();
    } else if (_allMedia.containsKey(category)) {
      // Direct category match (e.g., 'Movies', 'TV Shows', 'Trending Now', 'Anime')
      return _allMedia[category] ?? [];
    } else {
      // General filter by genre/other tags (e.g., 'Action', 'Horror', 'English')
      return _allMedia.values.expand((list) => list).where((media) {
        // Filter by genre
        if (media.genres.contains(category)) return true;
        
        // Simple filter by language (e.g., assuming category 'English' filters where language is 'en')
        // Note: This needs proper language mapping in a real app, but for now we'll assume the category name matches a genre or a simplified tag.
        return false;
      }).toList();
    }
  }

  // ----------------------------------------------------------------------
  // BUILD METHOD
  // ----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final List<Media>? trendingList = _allMedia['Trending Now'];
    final Media? trendingMedia = (trendingList != null && trendingList.isNotEmpty) ? trendingList[0] : null;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black, // Ensure background is dark
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: const Text(
          'StreamVerse',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Get all media items for search
              final allSearchableMedia = _allMedia.values.expand((list) => list).toList();

              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  pageBuilder: (context, animation, secondaryAnimation) => SearchPage(
                    allMedia: allSearchableMedia,
                    onLike: _addLikedMedia,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.search, color: Colors.white),
          ),
          IconButton(
            onPressed: () async {
              await AuthService.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.red),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.movie, size: 50, color: Colors.white),
                  SizedBox(height: 10),
                  Text('StreamVerse Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
                ],
              ),
            ),
            // Drawer menu items...
            ListTile(leading: const Icon(Icons.trending_up, color: Colors.white), title: const Text('Home', style: TextStyle(color: Colors.white)), onTap: () {_filterByCategory('Trending Now'); Navigator.pop(context);}),
            ListTile(leading: const Icon(Icons.movie, color: Colors.white), title: const Text('Movies', style: TextStyle(color: Colors.white)), onTap: () {_filterByCategory('Movies'); Navigator.pop(context);}),
            ListTile(leading: const Icon(Icons.live_tv, color: Colors.white), title: const Text('TV Shows', style: TextStyle(color: Colors.white)), onTap: () {_filterByCategory('TV Shows'); Navigator.pop(context);}),
            ListTile(leading: const Icon(Icons.animation, color: Colors.white), title: const Text('Anime', style: TextStyle(color: Colors.white)), onTap: () {_filterByCategory('Anime'); Navigator.pop(context);}),
            ListTile(leading: const Icon(Icons.recommend, color: Colors.white), title: const Text('Recommended for You', style: TextStyle(color: Colors.white)), onTap: () {_filterByCategory('Recommended'); Navigator.pop(context);}),
            ListTile(leading: const Icon(Icons.category, color: Colors.white), title: const Text('Categories', style: TextStyle(color: Colors.white)), onTap: () {Navigator.pop(context); _showCategoriesDialog(context);}),
          ],
        ),
      ),
      // Handle the loading state in the body
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.red),
            )
          : SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Highlight Section (only on the main 'Trending Now' view)
                  if (trendingMedia != null && _currentCategory == 'Trending Now')
                    HighlightSection(
                      media: trendingMedia,
                      onTap: () {
                        // Navigation logic for HighlightSection
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 500),
                            pageBuilder: (context, animation, secondaryAnimation) => DetailPage(
                              media: trendingMedia,
                              onLike: _addLikedMedia,
                            ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),

                  // Dynamically generated MediaRows (Home view)
                  if (_currentCategory == 'Trending Now')
                    ..._allMedia.entries
                        .where((entry) => entry.key != 'Recommended' && entry.key != 'Trending Now')
                        .indexed
                        .map((entry) {
                          final index = entry.$1;
                          final key = entry.$2.key;
                          final items = entry.$2.value;

                          // Defensive check for animation list
                          if (index >= _rowAnimations.length) return const SizedBox.shrink();

                          return FadeTransition(
                            opacity: _animationController,
                            child: SlideTransition(
                              position: _rowAnimations[index],
                              child: MediaRow(
                                title: key,
                                items: items,
                                onTap: (media) {
                                  // Navigation logic for MediaRow item
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      transitionDuration: const Duration(milliseconds: 500),
                                      pageBuilder: (context, animation, secondaryAnimation) => DetailPage(
                                        media: media,
                                        onLike: _addLikedMedia,
                                      ),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(opacity: animation, child: child);
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        })
                        .toList()

                  // Single MediaRow for filtered views (Movies, TV Shows, Recommended, Genre)
                  else
                    MediaRow(
                      title: _currentCategory,
                      items: _getDisplayedMedia(_currentCategory),
                      onTap: (media) {
                        // Navigation logic for filtered MediaRow item
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 500),
                            pageBuilder: (context, animation, secondaryAnimation) => DetailPage(
                              media: media,
                              onLike: _addLikedMedia,
                            ),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}