// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symptom.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SymptomAdapter extends TypeAdapter<Symptom> {
  @override
  final int typeId = 4;

  @override
  Symptom read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Symptom(
      id: fields[0] as String,
      familyMemberId: fields[1] as String,
      timestamp: fields[2] as DateTime,
      type: fields[3] as SymptomType,
      data: (fields[4] as Map).cast<String, dynamic>(),
      note: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Symptom obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.familyMemberId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SymptomTypeAdapter extends TypeAdapter<SymptomType> {
  @override
  final int typeId = 3;

  @override
  SymptomType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SymptomType.fever;
      case 1:
        return SymptomType.cough;
      case 2:
        return SymptomType.vomit;
      case 3:
        return SymptomType.pain;
      case 4:
        return SymptomType.rash;
      case 5:
        return SymptomType.other;
      default:
        return SymptomType.fever;
    }
  }

  @override
  void write(BinaryWriter writer, SymptomType obj) {
    switch (obj) {
      case SymptomType.fever:
        writer.writeByte(0);
        break;
      case SymptomType.cough:
        writer.writeByte(1);
        break;
      case SymptomType.vomit:
        writer.writeByte(2);
        break;
      case SymptomType.pain:
        writer.writeByte(3);
        break;
      case SymptomType.rash:
        writer.writeByte(4);
        break;
      case SymptomType.other:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
