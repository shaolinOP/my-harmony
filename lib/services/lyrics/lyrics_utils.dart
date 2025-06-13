class LyricsEntry {
  final int time;
  final String text;
  final String? romanizedText;
  
  LyricsEntry(this.time, this.text, [this.romanizedText]);
  
  static final headLyricsEntry = LyricsEntry(0, '');
}

class LyricsUtils {
  static List<LyricsEntry> parseLyrics(String lyrics) {
    final lines = lyrics.split('\n');
    final entries = <LyricsEntry>[];
    
    for (final line in lines) {
      final match = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)').firstMatch(line);
      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final milliseconds = int.parse(match.group(3)!.padRight(3, '0'));
        final text = match.group(4)!;
        
        final timeInMs = (minutes * 60 * 1000) + (seconds * 1000) + milliseconds;
        
        String? romanized;
        if (isJapanese(text)) {
          romanized = romanizeJapanese(text);
        }
        
        entries.add(LyricsEntry(timeInMs, text, romanized));
      }
    }
    
    return entries;
  }
  
  static int findCurrentLineIndex(List<LyricsEntry> lines, int currentPosition) {
    if (lines.isEmpty) return -1;
    
    for (int i = lines.length - 1; i >= 0; i--) {
      if (currentPosition >= lines[i].time) {
        return i;
      }
    }
    
    return 0;
  }
  
  static bool isJapanese(String text) {
    // Simple check for Japanese characters
    final japaneseRegex = RegExp(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FAF]');
    return japaneseRegex.hasMatch(text);
  }
  
  static String romanizeJapanese(String text) {
    // This is a simplified romanization
    // In a real implementation, you would use a proper romanization library
    // For now, just return the original text
    return text;
  }
  
  static String formatTime(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final ms = duration.inMilliseconds % 1000;
    
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(ms ~/ 10).toString().padLeft(2, '0')}';
  }
  
  static String createLrcFormat(List<LyricsEntry> entries) {
    final buffer = StringBuffer();
    
    for (final entry in entries) {
      if (entry.text.isNotEmpty) {
        final timeStr = formatTime(entry.time);
        buffer.writeln('[$timeStr]${entry.text}');
      }
    }
    
    return buffer.toString();
  }
}