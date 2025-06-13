import 'package:hive/hive.dart';

part 'lyrics_entity.g.dart';

@HiveType(typeId: 10)
class LyricsEntity extends HiveObject {
  static const String lyricsNotFound = 'LYRICS_NOT_FOUND';
  
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String lyrics;
  
  @HiveField(2)
  String? providerName;
  
  @HiveField(3)
  DateTime? lastUpdated;
  
  LyricsEntity({
    required this.id,
    required this.lyrics,
    this.providerName,
    this.lastUpdated,
  });
  
  bool get isNotFound => lyrics == lyricsNotFound;
  bool get isSynced => lyrics.startsWith('[');
  bool get hasLyrics => lyrics.isNotEmpty && !isNotFound;
}