// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_attendance_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingAttendanceModelAdapter
    extends TypeAdapter<PendingAttendanceModel> {
  @override
  final int typeId = 0;

  @override
  PendingAttendanceModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingAttendanceModel(
      type: fields[0] as String,
      latitude: fields[1] as String,
      longitude: fields[2] as String,
      imagePath: fields[3] as String,
     
      savedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PendingAttendanceModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.imagePath)
     
      ..writeByte(5)
      ..write(obj.savedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingAttendanceModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
