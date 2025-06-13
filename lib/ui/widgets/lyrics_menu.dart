import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_service/audio_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/lyrics_entity.dart';
import '../../services/lyrics/advanced_lyrics_service.dart';
import '../../services/lyrics/lyrics_helper.dart';

class LyricsMenu extends StatefulWidget {
  final MediaItem mediaItem;
  final LyricsEntity? lyricsEntity;
  final VoidCallback onDismiss;
  
  const LyricsMenu({
    super.key,
    required this.mediaItem,
    required this.lyricsEntity,
    required this.onDismiss,
  });

  @override
  State<LyricsMenu> createState() => _LyricsMenuState();
}

class _LyricsMenuState extends State<LyricsMenu> {
  bool _showEditDialog = false;
  bool _showSearchDialog = false;
  bool _showSearchResults = false;
  bool _isSearching = false;
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final TextEditingController _lyricsController = TextEditingController();
  
  final List<LyricsResult> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.mediaItem.title;
    _artistController.text = widget.mediaItem.artist ?? '';
    _lyricsController.text = widget.lyricsEntity?.lyrics ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyrics Menu'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onDismiss,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildMenuItem(
                  icon: Icons.edit,
                  title: 'Edit Lyrics',
                  subtitle: 'Manually edit lyrics',
                  onTap: () => setState(() => _showEditDialog = true),
                ),
                _buildMenuItem(
                  icon: Icons.refresh,
                  title: 'Refetch Lyrics',
                  subtitle: 'Download lyrics again',
                  onTap: _refetchLyrics,
                ),
                _buildMenuItem(
                  icon: Icons.search,
                  title: 'Search Lyrics',
                  subtitle: 'Search from multiple providers',
                  onTap: () => setState(() => _showSearchDialog = true),
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Lyrics Settings',
                  subtitle: 'Configure lyrics providers',
                  onTap: _openLyricsSettings,
                ),
                _buildMenuItem(
                  icon: Icons.web,
                  title: 'Search Online',
                  subtitle: 'Search lyrics on the web',
                  onTap: _searchOnline,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomSheets(),
    );
  }
  
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
  
  Widget? _buildBottomSheets() {
    if (_showEditDialog) {
      return _buildEditDialog();
    } else if (_showSearchDialog) {
      return _buildSearchDialog();
    } else if (_showSearchResults) {
      return _buildSearchResultsDialog();
    }
    return null;
  }
  
  Widget _buildEditDialog() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Lyrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showEditDialog = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextField(
              controller: _lyricsController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                hintText: 'Enter lyrics here...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _showEditDialog = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveLyrics,
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchDialog() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Search Lyrics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showSearchDialog = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Song Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _artistController,
            decoration: const InputDecoration(
              labelText: 'Artist',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _showSearchDialog = false),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _searchLyrics,
                child: const Text('Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResultsDialog() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Search Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() => _showSearchResults = false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Center(child: CircularProgressIndicator())
          else if (_searchResults.isEmpty)
            const Center(child: Text('No lyrics found'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        result.lyrics,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Text(result.providerName),
                          if (result.lyrics.startsWith('['))
                            const Icon(Icons.sync, size: 16),
                        ],
                      ),
                      onTap: () => _selectSearchResult(result),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
  
  void _saveLyrics() async {
    await AdvancedLyricsService.saveLyrics(
      widget.mediaItem.id,
      _lyricsController.text,
    );
    
    setState(() => _showEditDialog = false);
    widget.onDismiss();
    
    Get.snackbar(
      'Success',
      'Lyrics saved successfully',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  void _refetchLyrics() async {
    widget.onDismiss();
    
    Get.snackbar(
      'Refetching',
      'Downloading lyrics...',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
    
    await AdvancedLyricsService.refetchLyrics(widget.mediaItem);
  }
  
  void _searchLyrics() async {
    setState(() {
      _showSearchDialog = false;
      _showSearchResults = true;
      _isSearching = true;
      _searchResults.clear();
    });
    
    await AdvancedLyricsService.getAllLyrics(
      song: widget.mediaItem,
      callback: (result) {
        setState(() {
          _searchResults.add(result);
        });
      },
    );
    
    setState(() => _isSearching = false);
  }
  
  void _selectSearchResult(LyricsResult result) async {
    await AdvancedLyricsService.saveLyrics(
      widget.mediaItem.id,
      result.lyrics,
      providerName: result.providerName,
    );
    
    setState(() => _showSearchResults = false);
    widget.onDismiss();
    
    Get.snackbar(
      'Success',
      'Lyrics updated from ${result.providerName}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  void _openLyricsSettings() {
    // TODO: Navigate to lyrics settings page
    Get.snackbar(
      'Settings',
      'Lyrics settings will be implemented',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  void _searchOnline() async {
    final query = '${_artistController.text} ${_titleController.text} lyrics';
    final url = 'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
    
    widget.onDismiss();
  }
}