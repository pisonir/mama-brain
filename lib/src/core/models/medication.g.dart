// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicationAdapter extends TypeAdapter<Medication> {
  @override
  final int typeId = 2;

  @override
  Medication read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Medication(
      id: fields[0] as String,
      name: fields[1] as String,
      familyMemberId: fields[2] as String,
      type: fields[3] as MedicationType,
      startDate: fields[4] as DateTime,
      durationInDays: fields[5] as int?,
      takenLogs: (fields[6] as List).cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.familyMemberId)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.durationInDays)
      ..writeByte(6)
      ..write(obj.takenLogs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MedicationTypeAdapter extends TypeAdapter<MedicationType> {
  @override
  final int typeId = 1;

  @override
  MedicationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MedicationType.oneOff;
      case 1:
        return MedicationType.temporary;
      case 2:
        return MedicationType.permanent;
      default:
        return MedicationType.oneOff;
    }
  }

  @override
  void write(BinaryWriter writer, MedicationType obj) {
    switch (obj) {
      case MedicationType.oneOff:
        writer.writeByte(0);
        break;
      case MedicationType.temporary:
        writer.writeByte(1);
        break;
      case MedicationType.permanent:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
