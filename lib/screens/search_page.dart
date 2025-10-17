import 'package:flutter/material.dart';
import 'package:movie/models/media.dart';
import 'package:movie/screens/detail_page.dart';

class SearchPage extends StatefulWidget {
  final List<Media> allMedia;
  final Function(Media media) onLike;

  const SearchPage({
    super.key,
    required this.allMedia,
    required this.onLike,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Media> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _search(title: _searchController.text);
  }

  void _search({String? title}) {
    final results = widget.allMedia.where((media) {
      if (title != null && title.isNotEmpty) {
        return media.title.toLowerCase().contains(title.toLowerCase());
      }
      return false;
    }).toList();

    setState(() {
      _searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for movies or TV shows...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(
                    child: Text('No results found.',
                        style: TextStyle(fontSize: 18)),
                  )
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final media = _searchResults[index];
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(
                                media: media,
                                onLike: widget.onLike, // Pass the callback here
                              ),
                            ),
                          );
                        },
                        leading: Image.asset(
                          media.imagePath,
                          width: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(media.title),
                        subtitle: Text(media.genres.join(', ')),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}