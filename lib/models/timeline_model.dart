import 'package:hive/hive.dart';
import 'milestone_model.dart';

class TimelineModel extends HiveObject {
  String localId;
  String farmerId;
  String cropType;
  double landSizeAcres;
  String soilType;
  double latitude;
  double longitude;
  DateTime plantingDate;
  DateTime expectedHarvestDate;
  List<MilestoneModel> milestones;
  String status; // active | completed | abandoned
  String syncStatus; // synced | pending | conflict
  DateTime lastLocalModifiedAt;
  DateTime? lastSyncedAt;

  TimelineModel({
    required this.localId,
    required this.farmerId,
    required this.cropType,
    required this.landSizeAcres,
    required this.soilType,
    required this.latitude,
    required this.longitude,
    required this.plantingDate,
    required this.expectedHarvestDate,
    required this.milestones,
    this.status = "active",
    this.syncStatus = "pending",
    required this.lastLocalModifiedAt,
    this.lastSyncedAt,
  });

  double get progressPercent {
    if (milestones.isEmpty) return 0;
    final completed = milestones.where((m) => m.isCompleted).length;
    return (completed / milestones.length) * 100;
  }

  Map<String, dynamic> toSyncJson() => {
        "localId": localId,
        "farmer": farmerId,
        "cropType": cropType,
        "landSizeAcres": landSizeAcres,
        "soilType": soilType,
        "gpsLocation": {
          "type": "Point",
          "coordinates": [longitude, latitude],
        },
        "plantingDate": plantingDate.toIso8601String(),
        "expectedHarvestDate": expectedHarvestDate.toIso8601String(),
        "milestones": milestones.map((m) => m.toJson()).toList(),
        "status": status,
        "lastLocalModifiedAt": lastLocalModifiedAt.toIso8601String(),
      };
}

class TimelineModelAdapter extends TypeAdapter<TimelineModel> {
  @override
  final int typeId = 0;

  @override
  TimelineModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return TimelineModel(
      localId: fields[0] as String,
      farmerId: fields[1] as String,
      cropType: fields[2] as String,
      landSizeAcres: fields[3] as double,
      soilType: fields[4] as String,
      latitude: fields[5] as double,
      longitude: fields[6] as double,
      plantingDate: DateTime.parse(fields[7] as String),
      expectedHarvestDate: DateTime.parse(fields[8] as String),
      milestones: (fields[9] as List).cast<MilestoneModel>(),
      status: fields[10] as String,
      syncStatus: fields[11] as String,
      lastLocalModifiedAt: DateTime.parse(fields[12] as String),
      lastSyncedAt: fields[13] != null ? DateTime.parse(fields[13] as String) : null,
    );
  }

  @override
  void write(BinaryWriter writer, TimelineModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.localId)
      ..writeByte(1)
      ..write(obj.farmerId)
      ..writeByte(2)
      ..write(obj.cropType)
      ..writeByte(3)
      ..write(obj.landSizeAcres)
      ..writeByte(4)
      ..write(obj.soilType)
      ..writeByte(5)
      ..write(obj.latitude)
      ..writeByte(6)
      ..write(obj.longitude)
      ..writeByte(7)
      ..write(obj.plantingDate.toIso8601String())
      ..writeByte(8)
      ..write(obj.expectedHarvestDate.toIso8601String())
      ..writeByte(9)
      ..write(obj.milestones)
      ..writeByte(10)
      ..write(obj.status)
      ..writeByte(11)
      ..write(obj.syncStatus)
      ..writeByte(12)
      ..write(obj.lastLocalModifiedAt.toIso8601String())
      ..writeByte(13)
      ..write(obj.lastSyncedAt?.toIso8601String());
  }
}
