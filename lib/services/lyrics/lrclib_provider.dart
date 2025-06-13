import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'lyrics_provider.dart';

class LrcLibProvider extends LyricsProvider {
  static final Dio _dio = Dio();
  
  @override
  String get name => 'LrcLib';
  
  @override
  bool isEnabled() {
    final box = Hive.box('AppPrefs');
    return box.get('enableLrcLib', defaultValue: true);
  }
  
  @override
  Future<String?> getLyrics({
    required String id,
    required String title,
    required String artist,
    required int duration,
  }) async {
    try {
      final tracks = await _queryLyrics(artist: artist, title: title);
      final bestMatch = _findBestMatch(tracks, duration);
      return bestMatch?['syncedLyrics'] ?? bestMatch?['plainLyrics'];
    } catch (e) {
      print('LrcLib error: $e');
      return null;
    }
  }
  
  @override
  Future<void> getAllLyrics({
    required String id,
    required String title,
    required String artist,
    required int duration,
    required Function(String lyrics) callback,
  }) async {
    try {
      final tracks = await _queryLyrics(artist: artist, title: title);
      int count = 0;
      int plainCount = 0;
      
      for (final track in tracks) {
        if (count > 4) break;
        
        final trackDuration = track['duration'] as int? ?? 0;
        
        if (duration == -1 || (trackDuration - duration).abs() <= 2) {
          if (track['syncedLyrics'] != null && track['syncedLyrics'].toString().isNotEmpty) {
            count++;
            callback(track['syncedLyrics']);
          }
          
          if (track['plainLyrics'] != null && 
              track['plainLyrics'].toString().isNotEmpty && 
              plainCount == 0) {
            count++;
            plainCount++;
            callback(track['plainLyrics']);
          }
        }
      }
    } catch (e) {
      print('LrcLib getAllLyrics error: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> _queryLyrics({
    required String artist,
    required String title,
    String? album,
  }) async {
    final response = await _dio.get(
      'https://lrclib.net/api/search',
      queryParameters: {
        'track_name': title,
        'artist_name': artist,
        if (album != null) 'album_name': album,
      },
    );
    
    final List<dynamic> data = response.data;
    return data
        .cast<Map<String, dynamic>>()
        .where((track) => track['syncedLyrics'] != null || track['plainLyrics'] != null)
        .toList();
  }
  
  Map<String, dynamic>? _findBestMatch(List<Map<String, dynamic>> tracks, int duration) {
    if (tracks.isEmpty) return null;
    
    // Find exact duration match first
    for (final track in tracks) {
      final trackDuration = track['duration'] as int? ?? 0;
      if ((trackDuration - duration).abs() <= 2) {
        if (track['syncedLyrics'] != null) {
          return track;
        }
      }
    }
    
    // Fallback to first available track with lyrics
    return tracks.firstWhere(
      (track) => track['syncedLyrics'] != null || track['plainLyrics'] != null,
      orElse: () => tracks.first,
    );
  }
}