abstract class LyricsProvider {
  String get name;
  
  bool isEnabled();
  
  Future<String?> getLyrics({
    required String id,
    required String title,
    required String artist,
    required int duration,
  });
  
  Future<void> getAllLyrics({
    required String id,
    required String title,
    required String artist,
    required int duration,
    required Function(String lyrics) callback,
  }) async {
    final lyrics = await getLyrics(
      id: id,
      title: title,
      artist: artist,
      duration: duration,
    );
    if (lyrics != null) {
      callback(lyrics);
    }
  }
}