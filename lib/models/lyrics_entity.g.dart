// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lyrics_entity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LyricsEntityAdapter extends TypeAdapter<LyricsEntity> {
  @override
  final int typeId = 10;

  @override
  LyricsEntity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LyricsEntity(
      id: fields[0] as String,
      lyrics: fields[1] as String,
      providerName: fields[2] as String?,
      lastUpdated: fields[3] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, LyricsEntity obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lyrics)
      ..writeByte(2)
      ..write(obj.providerName)
      ..writeByte(3)
      ..write(obj.lastUpdated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LyricsEntityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}