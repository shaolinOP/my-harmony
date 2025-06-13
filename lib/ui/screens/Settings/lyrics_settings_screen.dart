import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../../services/lyrics/advanced_lyrics_service.dart';
import '../../../services/lyrics/lyrics_helper.dart';

class LyricsSettingsScreen extends StatefulWidget {
  const LyricsSettingsScreen({super.key});

  @override
  State<LyricsSettingsScreen> createState() => _LyricsSettingsScreenState();
}

class _LyricsSettingsScreenState extends State<LyricsSettingsScreen> {
  late PreferredLyricsProvider _preferredProvider;
  late bool _enableLrcLib;
  late bool _enableKugou;
  late bool _enableYoutube;
  late bool _lyricsClick;
  late int _lyricsTextPosition;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _preferredProvider = AdvancedLyricsService.getPreferredProvider();
    _enableLrcLib = AdvancedLyricsService.isProviderEnabled('lrclib');
    _enableKugou = AdvancedLyricsService.isProviderEnabled('kugou');
    _enableYoutube = AdvancedLyricsService.isProviderEnabled('youtube');
    
    final box = Hive.box('AppPrefs');
    _lyricsClick = box.get('lyricsClick', defaultValue: true);
    _lyricsTextPosition = box.get('lyricsTextPosition', defaultValue: 1); // 0: left, 1: center, 2: right
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyrics Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Lyrics Providers'),
          _buildProviderTile(
            'LrcLib',
            'Community-driven lyrics database',
            _enableLrcLib,
            (value) {
              setState(() => _enableLrcLib = value);
              AdvancedLyricsService.setProviderEnabled('lrclib', value);
            },
          ),
          _buildProviderTile(
            'KuGou',
            'Chinese lyrics provider',
            _enableKugou,
            (value) {
              setState(() => _enableKugou = value);
              AdvancedLyricsService.setProviderEnabled('kugou', value);
            },
          ),
          _buildProviderTile(
            'YouTube',
            'YouTube Music lyrics',
            _enableYoutube,
            (value) {
              setState(() => _enableYoutube = value);
              AdvancedLyricsService.setProviderEnabled('youtube', value);
            },
          ),
          
          const Divider(),
          _buildSectionHeader('Provider Priority'),
          _buildPreferredProviderTile(),
          
          const Divider(),
          _buildSectionHeader('Display Settings'),
          _buildLyricsClickTile(),
          _buildLyricsPositionTile(),
          
          const Divider(),
          _buildSectionHeader('Cache Management'),
          _buildCacheManagementTile(),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  Widget _buildProviderTile(
    String name,
    String description,
    bool enabled,
    Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(name),
      subtitle: Text(description),
      value: enabled,
      onChanged: onChanged,
    );
  }
  
  Widget _buildPreferredProviderTile() {
    return ListTile(
      title: const Text('Preferred Provider'),
      subtitle: Text('Primary provider: ${_preferredProvider.name}'),
      trailing: DropdownButton<PreferredLyricsProvider>(
        value: _preferredProvider,
        items: PreferredLyricsProvider.values.map((provider) {
          return DropdownMenuItem(
            value: provider,
            child: Text(provider.name),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() => _preferredProvider = value);
            AdvancedLyricsService.setPreferredProvider(value);
          }
        },
      ),
    );
  }
  
  Widget _buildLyricsClickTile() {
    return SwitchListTile(
      title: const Text('Lyrics Click'),
      subtitle: const Text('Allow clicking on lyrics to seek'),
      value: _lyricsClick,
      onChanged: (value) {
        setState(() => _lyricsClick = value);
        Hive.box('AppPrefs').put('lyricsClick', value);
      },
    );
  }
  
  Widget _buildLyricsPositionTile() {
    return ListTile(
      title: const Text('Lyrics Text Position'),
      subtitle: Text(_getPositionText(_lyricsTextPosition)),
      trailing: DropdownButton<int>(
        value: _lyricsTextPosition,
        items: const [
          DropdownMenuItem(value: 0, child: Text('Left')),
          DropdownMenuItem(value: 1, child: Text('Center')),
          DropdownMenuItem(value: 2, child: Text('Right')),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _lyricsTextPosition = value);
            Hive.box('AppPrefs').put('lyricsTextPosition', value);
          }
        },
      ),
    );
  }
  
  Widget _buildCacheManagementTile() {
    return ListTile(
      title: const Text('Clear Lyrics Cache'),
      subtitle: const Text('Remove all cached lyrics'),
      trailing: ElevatedButton(
        onPressed: _clearCache,
        child: const Text('Clear'),
      ),
    );
  }
  
  String _getPositionText(int position) {
    switch (position) {
      case 0: return 'Left aligned';
      case 1: return 'Center aligned';
      case 2: return 'Right aligned';
      default: return 'Center aligned';
    }
  }
  
  void _clearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached lyrics?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // Clear lyrics cache
              final lyricsBox = await Hive.openBox('lyrics');
              await lyricsBox.clear();
              await lyricsBox.close();
              
              Get.snackbar(
                'Success',
                'Lyrics cache cleared',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}