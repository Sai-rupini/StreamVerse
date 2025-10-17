// lib/screens/detail_page.dart
import 'package:flutter/material.dart';
import 'package:movie/models/media.dart';
import 'package:movie/services/media_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:math';

class DetailPage extends StatefulWidget {
  final Media media;
  final Function(Media media)? onLike;
  
  const DetailPage({
    super.key,
    required this.media,
    this.onLike,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> with TickerProviderStateMixin {
  // ⭐️ UPDATED STATE: Use a single Media object for all detailed data
  Media _detailedMedia = const Media(
    id: -1, mediaType: 'movie', title: '', imagePath: '', 
    plot: 'Loading details...', imdbRating: 'N/A', 
    genres: [], actors: [], directors: [], trailerUrl: null, // Ensure trailerUrl is initialized
  );
  bool _isLoadingDetails = true;
  
  YoutubePlayerController? _youtubeController;
  final MediaService _mediaService = MediaService();

  late AnimationController _pageAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  double _playButtonScale = 1.0;
  Map<String, double> _ratingButtonScale = {
    'Disliked': 1.0,
    'Liked': 1.0,
    'Loved it': 1.0,
  };

  @override
  void initState() {
    super.initState();

    _pageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _pageAnimationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _pageAnimationController,
      curve: Curves.easeOut,
    ));

    _pageAnimationController.forward();

    // ⭐️ INITIALIZE DETAILED MEDIA WITH WIDGET.MEDIA
    _detailedMedia = widget.media;
    
    // ⭐️ CALL: Start the single, unified API fetch
    _fetchMediaDetails();
  }
  
  // ⭐️ NEW/UPDATED METHOD: Fetch all details (trailer, cast, crew) in one call
  Future<void> _fetchMediaDetails() async {
    try {
      // Use the new single method to get the fully populated Media object
      final completeMedia = await _mediaService.fetchMediaDetails(widget.media); 
      
      if (mounted) {
        setState(() {
          _detailedMedia = completeMedia;
          _isLoadingDetails = false;
        });

        // ⭐️ UPDATED TRAILER CONTROLLER INITIALIZATION (Moved here after API call)
        if (_detailedMedia.trailerUrl != null &&
            _detailedMedia.trailerUrl!.isNotEmpty) {
          _youtubeController = YoutubePlayerController(
            initialVideoId: _detailedMedia.trailerUrl!, // trailerUrl is now the KEY
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          );
        }
      }
    } catch (e) {
      print("Error fetching media details: $e");
      if (mounted) {
        setState(() {
          _isLoadingDetails = false; 
        });
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _pageAnimationController.dispose();
    super.dispose();
  }

  void _showRatingSnackBar(BuildContext context, String rating) {
    if (rating == 'Liked' || rating == 'Loved it') {
      widget.onLike?.call(widget.media);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('You rated "${widget.media.title}" as "$rating"!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _playTrailer() {
    // Uses _detailedMedia.trailerUrl, which holds the YouTube KEY
    if (_youtubeController != null) {
      // Reset the player before showing the dialog
      _youtubeController!.pause();
      
      showDialog(
        context: context,
        builder: (context) => ScaleTransition(
          scale: CurvedAnimation(
            parent: _pageAnimationController,
            curve: Curves.easeOutBack,
          ),
          child: Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(10),
            child: Stack(
              children: [
                SizedBox(
                  height: 250,
                  child: YoutubePlayer(
                    controller: _youtubeController!,
                    showVideoProgressIndicator: true,
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: GestureDetector(
                    onTap: () {
                      _youtubeController!.pause(); // Pause video on close
                      Navigator.of(context).pop();
                    },
                    child: const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trailer not available'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // WIDGET: Helper to display the Cast/Crew lists
  Widget _buildCastList(List<String> items, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }
    
    if (items.isEmpty) {
      return const Text('Information not available.', style: TextStyle(fontStyle: FontStyle.italic));
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: items.map((item) => Chip(
        label: Text(item),
        backgroundColor: Colors.grey.shade800,
        labelStyle: const TextStyle(color: Colors.white70),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which media object to use (the partial one or the fully loaded one)
    final displayMedia = _detailedMedia.id != -1 ? _detailedMedia : widget.media; 
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Text(widget.media.title),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroImageSection(), 
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _animatedSection(
                        title: "Plot Summary",
                        child: Text(displayMedia.plot, // Use displayMedia
                            style: const TextStyle(fontSize: 16)),
                      ),
                      _animatedSection(
                        title: "Genres",
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: displayMedia.genres // Use displayMedia
                              .map((genre) => Chip(label: Text(genre)))
                              .toList(),
                        ),
                      ),
                      
                      // ACTORS: Use the list from the _detailedMedia state
                      _animatedSection(
                        title: "Actors",
                        child: _buildCastList(displayMedia.actors, _isLoadingDetails),
                      ),
                      
                      // DIRECTORS: Use the list from the _detailedMedia state
                      _animatedSection(
                        title: "Directors",
                        child: _buildCastList(displayMedia.directors, _isLoadingDetails),
                      ),
                      
                      const SizedBox(height: 30),
                      const Text(
                        'Rate this Movie/TV Show',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['Disliked', 'Liked', 'Loved it']
                            .map((rating) => _animatedRatingButton(
                                  rating,
                                  _getIconForRating(rating),
                                  _getColorForRating(rating),
                                  context,
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 30),
                      _playTrailerButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ... (rest of the helper methods: _heroImageSection, _animatedSection, _animatedRatingButton, _getIconForRating, _getColorForRating, _showConfetti) ...
  
  Widget _heroImageSection() {
    return Stack(
      children: [
        Hero(
          tag: widget.media.title,
          child: Image.network( 
            widget.media.fullImageUrl, 
            fit: BoxFit.cover,
            width: double.infinity,
            height: 300,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 300,
                color: Colors.grey.shade900,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 300,
                color: Colors.red.shade900,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image, color: Colors.white, size: 50),
              );
            },
          ),
        ),
        Container(
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: 10,
          right: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedDefaultTextStyle(
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                duration: const Duration(milliseconds: 500),
                child: Text(widget.media.title),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 5),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                        begin: 0, end: double.parse(widget.media.imdbRating)),
                    duration: const Duration(milliseconds: 800),
                    builder: (context, value, child) => Text(
                      value.toStringAsFixed(1),
                      style:
                          const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  const Text('IMDb Rating',
                      style: TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _animatedSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedOpacity(
            opacity: 1.0,
            duration: const Duration(milliseconds: 600),
            child: Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0.1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _pageAnimationController,
              curve: Curves.easeInOut,
            )),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _animatedRatingButton(
      String text, IconData icon, Color color, BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _ratingButtonScale[text] = 1.4),
      onTapUp: (details) {
        setState(() => _ratingButtonScale[text] = 1.0);
        _showRatingSnackBar(context, text);
        _showConfetti(context, color, details.globalPosition);
      },
      onTapCancel: () => setState(() => _ratingButtonScale[text] = 1.0),
      child: AnimatedScale(
        scale: _ratingButtonScale[text]!,
        duration: const Duration(milliseconds: 200),
        curve: Curves.elasticOut,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3), // Reduced glow
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) => RotationTransition(
                    turns: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Icon(icon, key: ValueKey(icon), color: color, size: 45),
                ),
                Text(text,
                    style: TextStyle(
                        color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForRating(String rating) {
    switch (rating) {
      case 'Disliked':
        return Icons.thumb_down;
      case 'Liked':
        return Icons.thumb_up;
      case 'Loved it':
        return Icons.favorite;
      default:
        return Icons.star;
    }
  }

  Color _getColorForRating(String rating) {
    switch (rating) {
      case 'Disliked':
        return Colors.red;
      case 'Liked':
        return Colors.blue;
      case 'Loved it':
        return Colors.pink;
      default:
        return Colors.amber;
    }
  }

  Widget _playTrailerButton() {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => setState(() => _playButtonScale = 1.1),
        onTapUp: (_) {
          setState(() => _playButtonScale = 1.0);
          _playTrailer();
        },
        onTapCancel: () => setState(() => _playButtonScale = 1.0),
        child: AnimatedScale(
          scale: _playButtonScale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: ElevatedButton.icon(
            onPressed: _playTrailer,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play Trailer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shadowColor: Colors.redAccent,
              elevation: 12,
            ),
          ),
        ),
      ),
    );
  }

  void _showConfetti(BuildContext context, Color color, Offset position) {
    final overlay = Overlay.of(context);
    final random = Random();

    OverlayEntry entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: List.generate(20, (index) {
            final startX = position.dx;
            final startY = position.dy;
            final endX = startX + random.nextDouble() * 120 - 60;
            final endY = startY + random.nextDouble() * 120 - 60;

            return TweenAnimationBuilder(
              tween: Tween<Offset>(
                  begin: Offset(startX, startY), end: Offset(endX, endY)),
              duration: Duration(milliseconds: 700 + random.nextInt(300)),
              builder: (context, Offset offset, child) {
                return Positioned(
                  left: offset.dx,
                  top: offset.dy,
                  child: Opacity(
                    opacity: 1.0 - (offset.dy - startY) / 150,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ),
                );
              },
            );
          }),
        );
      },
    );

    overlay.insert(entry);

    Future.delayed(const Duration(milliseconds: 900), () {
      entry.remove();
    });
  }
}