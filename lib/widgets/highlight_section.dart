import 'package:flutter/material.dart';
import 'package:movie/models/media.dart';

class HighlightSection extends StatefulWidget {
  final Media media;
  final VoidCallback onTap;

  const HighlightSection({
    super.key,
    required this.media,
    required this.onTap,
  });

  @override
  _HighlightSectionState createState() => _HighlightSectionState();
}

class _HighlightSectionState extends State<HighlightSection>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _buttonScaleController;
  late Animation<double> _buttonScaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize fade-in animation for the poster
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();

    // Initialize scale animation for the button
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _buttonScaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _buttonScaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _buttonScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Fade-in movie poster using Image.network
          FadeTransition(
            opacity: _fadeAnimation,
            child: Image.network(
              widget.media.fullImageUrl, // ⭐️ CRITICAL FIX: Use fullImageUrl for network
              height: 500,
              width: double.infinity,
              fit: BoxFit.cover,
              // Add loading and error builders for better UX
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 500,
                  color: Colors.grey.shade900,
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(color: Colors.white70),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 500,
                  color: Colors.red.shade900,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, color: Colors.white, size: 50),
                );
              },
            ),
          ),
          Container(
            height: 500,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  widget.media.title,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.media.plot,
                  style: const TextStyle(fontSize: 16),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Scale animation on More Info button
                GestureDetector(
                  onTapDown: (_) => _buttonScaleController.forward(),
                  onTapUp: (_) => _buttonScaleController.reverse(),
                  onTapCancel: () => _buttonScaleController.reverse(),
                  onTap: widget.onTap,
                  child: ScaleTransition(
                    scale: _buttonScaleAnimation,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _buttonScaleController.reverse();
                        widget.onTap();
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('More Info'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}