import 'package:flutter/material.dart';
import 'package:movie/models/media.dart';

class MediaRow extends StatefulWidget {
  final String title;
  final List<Media> items;
  final Function(Media) onTap;

  const MediaRow({
    super.key,
    required this.title,
    required this.items,
    required this.onTap,
  });

  @override
  State<MediaRow> createState() => _MediaRowState();
}

class _MediaRowState extends State<MediaRow> {
  final ScrollController _scrollController = ScrollController();

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200, // Scroll by a fixed amount
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200, // Scroll by a fixed amount
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ Safety check: If the items list is empty, return an empty space.
    // This prevents drawing the title and scroll buttons if there's no content.
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Scroll Left Button
            IconButton(
              onPressed: _scrollLeft,
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            ),
            Expanded(
              child: SizedBox(
                height: 180, 
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final media = widget.items[index];
                    
                    // ⚠️ Secondary Safety Check: Skip items without a valid image path
                    if (media.imagePath.isEmpty) {
                        return const SizedBox.shrink();
                    }
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              widget.onTap(media);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.network( // ⭐️ CRITICAL CHANGE
                                media.fullImageUrl, // ⭐️ MUST use the full URL property you created
                                fit: BoxFit.cover,
                                width: 120,
                                height: 160,
                                // Add error handling for network failure
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 160,
                                    color: Colors.grey.shade800,
                                    child: const Center(
                                      child: Icon(Icons.movie_filter, color: Colors.white54),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          SizedBox(
                            width: 120,
                            child: Text(
                              media.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Scroll Right Button
            IconButton(
              onPressed: _scrollRight,
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            ),
          ],
        ),
      ],
    );
  }
}