import 'package:audio_service/audio_service.dart';
import 'package:hive/hive.dart';
import '../../models/lyrics_entity.dart';
import 'lyrics_helper.dart';

class AdvancedLyricsService {
  static final LyricsHelper _lyricsHelper = LyricsHelper();
  static const String _boxName = 'lyrics';
  
  static Future<LyricsEntity?> getLyrics(MediaItem song) async {
    final lyricsBox = await Hive.openBox<LyricsEntity>(_boxName);
    
    // Check if lyrics available in local database
    if (lyricsBox.containsKey(song.id)) {
      final cached = lyricsBox.get(song.id);
      if (cached != null && !_shouldRefetch(cached)) {
        return cached;
      }
    }
    
    try {
      final lyrics = await _lyricsHelper.getLyrics(song);
      
      final entity = LyricsEntity(
        id: song.id,
        lyrics: lyrics,
        lastUpdated: DateTime.now(),
      );
      
      await lyricsBox.put(song.id, entity);
      return entity;
    } catch (e) {
      print('Error fetching lyrics: $e');
      
      // Return not found entity
      final entity = LyricsEntity(
        id: song.id,
        lyrics: LyricsEntity.lyricsNotFound,
        lastUpdated: DateTime.now(),
      );
      
      await lyricsBox.put(song.id, entity);
      return entity;
    } finally {
      await lyricsBox.close();
    }
  }
  
  static Future<void> getAllLyrics({
    required MediaItem song,
    required Function(LyricsResult) callback,
  }) async {
    final duration = song.duration?.inSeconds ?? -1;
    
    await _lyricsHelper.getAllLyrics(
      mediaId: song.id,
      songTitle: song.title,
      songArtists: song.artist ?? '',
      duration: duration,
      callback: callback,
    );
  }
  
  static Future<void> saveLyrics(String songId, String lyrics, {String? providerName}) async {
    final lyricsBox = await Hive.openBox<LyricsEntity>(_boxName);
    
    final entity = LyricsEntity(
      id: songId,
      lyrics: lyrics,
      providerName: providerName,
      lastUpdated: DateTime.now(),
    );
    
    await lyricsBox.put(songId, entity);
    await lyricsBox.close();
  }
  
  static Future<void> deleteLyrics(String songId) async {
    final lyricsBox = await Hive.openBox<LyricsEntity>(_boxName);
    await lyricsBox.delete(songId);
    await lyricsBox.close();
  }
  
  static Future<void> refetchLyrics(MediaItem song) async {
    // Delete cached lyrics to force refetch
    await deleteLyrics(song.id);
    
    // Fetch new lyrics
    await getLyrics(song);
  }
  
  static bool _shouldRefetch(LyricsEntity entity) {
    if (entity.lastUpdated == null) return true;
    
    // Refetch if lyrics are older than 7 days
    final daysSinceUpdate = DateTime.now().difference(entity.lastUpdated!).inDays;
    return daysSinceUpdate > 7;
  }
  
  static void setPreferredProvider(PreferredLyricsProvider provider) {
    _lyricsHelper.setPreferredProvider(provider);
  }
  
  static PreferredLyricsProvider getPreferredProvider() {
    return _lyricsHelper.getPreferredProvider();
  }
  
  static void setProviderEnabled(String providerName, bool enabled) {
    _lyricsHelper.setProviderEnabled(providerName, enabled);
  }
  
  static bool isProviderEnabled(String providerName) {
    return _lyricsHelper.isProviderEnabled(providerName);
  }
}