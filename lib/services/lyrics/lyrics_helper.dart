import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import 'lyrics_provider.dart';
import 'lrclib_provider.dart';
import 'kugou_provider.dart';
import 'youtube_provider.dart';

enum PreferredLyricsProvider { lrclib, kugou }

class LyricsResult {
  final String providerName;
  final String lyrics;
  
  LyricsResult(this.providerName, this.lyrics);
}

class LyricsHelper {
  static const String lyricsNotFound = 'LYRICS_NOT_FOUND';
  static const int maxCacheSize = 3;
  
  late List<LyricsProvider> _providers;
  final Map<String, List<LyricsResult>> _cache = {};
  
  LyricsHelper() {
    _initializeProviders();
  }
  
  void _initializeProviders() {
    final box = Hive.box('AppPrefs');
    final preferred = PreferredLyricsProvider.values[
      box.get('preferredLyricsProvider', defaultValue: 0)
    ];
    
    if (preferred == PreferredLyricsProvider.lrclib) {
      _providers = [
        LrcLibProvider(),
        KuGouProvider(),
        YouTubeProvider(),
      ];
    } else {
      _providers = [
        KuGouProvider(),
        LrcLibProvider(),
        YouTubeProvider(),
      ];
    }
  }
  
  Future<String> getLyrics(MediaItem mediaItem) async {
    final cacheKey = '${mediaItem.artist}-${mediaItem.title}'.replaceAll(' ', '');
    final cached = _cache[cacheKey]?.first;
    if (cached != null) {
      return cached.lyrics;
    }
    
    final duration = mediaItem.duration?.inSeconds ?? -1;
    
    for (final provider in _providers) {
      if (provider.isEnabled()) {
        try {
          final lyrics = await provider.getLyrics(
            id: mediaItem.id,
            title: mediaItem.title,
            artist: mediaItem.artist ?? '',
            duration: duration,
          );
          
          if (lyrics != null && lyrics.isNotEmpty) {
            return lyrics;
          }
        } catch (e) {
          print('Error from ${provider.name}: $e');
        }
      }
    }
    
    return lyricsNotFound;
  }
  
  Future<void> getAllLyrics({
    required String mediaId,
    required String songTitle,
    required String songArtists,
    required int duration,
    required Function(LyricsResult) callback,
  }) async {
    final cacheKey = '$songArtists-$songTitle'.replaceAll(' ', '');
    
    // Check cache first
    final cached = _cache[cacheKey];
    if (cached != null) {
      for (final result in cached) {
        callback(result);
      }
      return;
    }
    
    final allResults = <LyricsResult>[];
    
    for (final provider in _providers) {
      if (provider.isEnabled()) {
        try {
          await provider.getAllLyrics(
            id: mediaId,
            title: songTitle,
            artist: songArtists,
            duration: duration,
            callback: (lyrics) {
              final result = LyricsResult(provider.name, lyrics);
              allResults.add(result);
              callback(result);
            },
          );
        } catch (e) {
          print('Error from ${provider.name}: $e');
        }
      }
    }
    
    // Cache results
    if (_cache.length >= maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = allResults;
  }
  
  void setPreferredProvider(PreferredLyricsProvider provider) {
    final box = Hive.box('AppPrefs');
    box.put('preferredLyricsProvider', provider.index);
    _initializeProviders();
  }
  
  PreferredLyricsProvider getPreferredProvider() {
    final box = Hive.box('AppPrefs');
    return PreferredLyricsProvider.values[
      box.get('preferredLyricsProvider', defaultValue: 0)
    ];
  }
  
  void setProviderEnabled(String providerName, bool enabled) {
    final box = Hive.box('AppPrefs');
    switch (providerName.toLowerCase()) {
      case 'lrclib':
        box.put('enableLrcLib', enabled);
        break;
      case 'kugou':
        box.put('enableKugou', enabled);
        break;
      case 'youtube':
        box.put('enableYoutube', enabled);
        break;
    }
  }
  
  bool isProviderEnabled(String providerName) {
    final box = Hive.box('AppPrefs');
    switch (providerName.toLowerCase()) {
      case 'lrclib':
        return box.get('enableLrcLib', defaultValue: true);
      case 'kugou':
        return box.get('enableKugou', defaultValue: true);
      case 'youtube':
        return box.get('enableYoutube', defaultValue: true);
      default:
        return false;
    }
  }
}