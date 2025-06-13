import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'lyrics_provider.dart';

class KuGouProvider extends LyricsProvider {
  static final Dio _dio = Dio();
  static const int _pageSize = 8;
  static const int _headCutLimit = 30;
  static const int _durationTolerance = 8;
  
  @override
  String get name => 'KuGou';
  
  @override
  bool isEnabled() {
    final box = Hive.box('AppPrefs');
    return box.get('enableKugou', defaultValue: true);
  }
  
  @override
  Future<String?> getLyrics({
    required String id,
    required String title,
    required String artist,
    required int duration,
  }) async {
    try {
      final keyword = _generateKeyword(title, artist);
      final candidate = await _getLyricsCandidate(keyword, duration);
      
      if (candidate != null) {
        final lyricsResponse = await _downloadLyrics(
          candidate['id'], 
          candidate['accesskey']
        );
        final content = lyricsResponse['content'] as String?;
        if (content != null) {
          final decodedContent = utf8.decode(base64.decode(content));
          return _normalizeLyrics(decodedContent);
        }
      }
      return null;
    } catch (e) {
      print('KuGou error: $e');
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
      final keyword = _generateKeyword(title, artist);
      
      // Search by songs first
      final songsResponse = await _searchSongs(keyword);
      final songs = songsResponse['data']?['info'] as List? ?? [];
      
      for (final song in songs) {
        final songDuration = song['duration'] as int? ?? 0;
        if (duration == -1 || (songDuration - duration).abs() <= _durationTolerance) {
          final hash = song['hash'] as String?;
          if (hash != null) {
            final lyricsResponse = await _searchLyricsByHash(hash);
            final candidates = lyricsResponse['candidates'] as List? ?? [];
            
            if (candidates.isNotEmpty) {
              final candidate = candidates.first;
              final downloadResponse = await _downloadLyrics(
                candidate['id'], 
                candidate['accesskey']
              );
              final content = downloadResponse['content'] as String?;
              if (content != null) {
                final decodedContent = utf8.decode(base64.decode(content));
                final normalizedLyrics = _normalizeLyrics(decodedContent);
                if (normalizedLyrics.isNotEmpty) {
                  callback(normalizedLyrics);
                }
              }
            }
          }
        }
      }
      
      // Search by keyword
      final keywordResponse = await _searchLyricsByKeyword(keyword, duration);
      final candidates = keywordResponse['candidates'] as List? ?? [];
      
      for (final candidate in candidates) {
        final downloadResponse = await _downloadLyrics(
          candidate['id'], 
          candidate['accesskey']
        );
        final content = downloadResponse['content'] as String?;
        if (content != null) {
          final decodedContent = utf8.decode(base64.decode(content));
          final normalizedLyrics = _normalizeLyrics(decodedContent);
          if (normalizedLyrics.isNotEmpty) {
            callback(normalizedLyrics);
          }
        }
      }
    } catch (e) {
      print('KuGou getAllLyrics error: $e');
    }
  }
  
  Future<Map<String, dynamic>?> _getLyricsCandidate(
    Map<String, String> keyword, 
    int duration
  ) async {
    // Search songs first
    final songsResponse = await _searchSongs(keyword);
    final songs = songsResponse['data']?['info'] as List? ?? [];
    
    for (final song in songs) {
      final songDuration = song['duration'] as int? ?? 0;
      if (duration == -1 || (songDuration - duration).abs() <= _durationTolerance) {
        final hash = song['hash'] as String?;
        if (hash != null) {
          final lyricsResponse = await _searchLyricsByHash(hash);
          final candidates = lyricsResponse['candidates'] as List? ?? [];
          if (candidates.isNotEmpty) {
            return candidates.first;
          }
        }
      }
    }
    
    // Fallback to keyword search
    final keywordResponse = await _searchLyricsByKeyword(keyword, duration);
    final candidates = keywordResponse['candidates'] as List? ?? [];
    return candidates.isNotEmpty ? candidates.first : null;
  }
  
  Future<Map<String, dynamic>> _searchSongs(Map<String, String> keyword) async {
    final response = await _dio.get(
      'https://mobileservice.kugou.com/api/v3/search/song',
      queryParameters: {
        'version': 9108,
        'plat': 0,
        'pagesize': _pageSize,
        'showtype': 0,
        'keyword': '${keyword['title']} - ${keyword['artist']}',
      },
    );
    return response.data;
  }
  
  Future<Map<String, dynamic>> _searchLyricsByKeyword(
    Map<String, String> keyword, 
    int duration
  ) async {
    final queryParams = {
      'ver': 1,
      'man': 'yes',
      'client': 'pc',
      'keyword': '${keyword['title']} - ${keyword['artist']}',
    };
    
    if (duration != -1) {
      queryParams['duration'] = (duration * 1000).toString();
    }
    
    final response = await _dio.get(
      'https://lyrics.kugou.com/search',
      queryParameters: queryParams,
    );
    return response.data;
  }
  
  Future<Map<String, dynamic>> _searchLyricsByHash(String hash) async {
    final response = await _dio.get(
      'https://lyrics.kugou.com/search',
      queryParameters: {
        'ver': 1,
        'man': 'yes',
        'client': 'pc',
        'hash': hash,
      },
    );
    return response.data;
  }
  
  Future<Map<String, dynamic>> _downloadLyrics(int id, String accessKey) async {
    final response = await _dio.get(
      'https://lyrics.kugou.com/download',
      queryParameters: {
        'fmt': 'lrc',
        'charset': 'utf8',
        'client': 'pc',
        'ver': 1,
        'id': id,
        'accesskey': accessKey,
      },
    );
    return response.data;
  }
  
  Map<String, String> _generateKeyword(String title, String artist) {
    return {
      'title': _normalizeTitle(title),
      'artist': _normalizeArtist(artist),
    };
  }
  
  String _normalizeTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*\)'), '')
        .replaceAll(RegExp(r'（.*）'), '')
        .replaceAll(RegExp(r'「.*」'), '')
        .replaceAll(RegExp(r'『.*』'), '')
        .replaceAll(RegExp(r'<.*>'), '')
        .replaceAll(RegExp(r'《.*》'), '')
        .replaceAll(RegExp(r'〈.*〉'), '')
        .replaceAll(RegExp(r'＜.*＞'), '');
  }
  
  String _normalizeArtist(String artist) {
    return artist
        .replaceAll(', ', '、')
        .replaceAll(' & ', '、')
        .replaceAll('.', '')
        .replaceAll('和', '、')
        .replaceAll(RegExp(r'\(.*\)'), '')
        .replaceAll(RegExp(r'（.*）'), '');
  }
  
  String _normalizeLyrics(String lyrics) {
    final lines = lyrics
        .replaceAll('&apos;', "'")
        .split('\n')
        .where((line) => RegExp(r'\[(\d\d):(\d\d)\.(\d{2,3})\].*').hasMatch(line))
        .toList();
    
    // Remove useless information
    int headCutLine = 0;
    final bannedRegex = RegExp(r'.+].+[:：].+');
    
    for (int i = min(_headCutLimit, lines.length - 1); i >= 0; i--) {
      if (bannedRegex.hasMatch(lines[i])) {
        headCutLine = i + 1;
        break;
      }
    }
    
    final filteredLines = lines.skip(headCutLine).toList();
    
    int tailCutLine = 0;
    for (int i = min(lines.length - _headCutLimit, lines.length - 1); i >= 0; i--) {
      final index = lines.length - 1 - i;
      if (index < lines.length && bannedRegex.hasMatch(lines[index])) {
        tailCutLine = i + 1;
        break;
      }
    }
    
    final finalLines = filteredLines.take(filteredLines.length - tailCutLine).toList();
    return finalLines.join('\n');
  }
}