import 'package:hive/hive.dart';
import '../localization/app_locale.dart';

class MilestoneModel {
  int day;
  String title;
  String description;
  String? titleSi;
  String? descriptionSi;
  bool isCompleted;
  DateTime? completedAt;
  bool weatherAlertTriggered;

  MilestoneModel({
    required this.day,
    required this.title,
    required this.description,
    this.titleSi,
    this.descriptionSi,
    this.isCompleted = false,
    this.completedAt,
    this.weatherAlertTriggered = false,
  });

  /// Returns the title in whichever language the farmer currently has
  /// selected, falling back to English if no Sinhala version was generated
  /// (e.g. milestones created before this feature existed).
  String get localizedTitle => AppLocale.instance.languageCode == "si" && titleSi != null ? titleSi! : title;

  String get localizedDescription =>
      AppLocale.instance.languageCode == "si" && descriptionSi != null ? descriptionSi! : description;

  Map<String, dynamic> toJson() => {
        "day": day,
        "title": title,
        "description": description,
        "isCompleted": isCompleted,
        "completedAt": completedAt?.toIso8601String(),
        "weatherAlertTriggered": weatherAlertTriggered,
      };
}

/// Manual Hive TypeAdapter — avoids needing `build_runner` codegen,
/// so this runs immediately without any extra setup step.
class MilestoneModelAdapter extends TypeAdapter<MilestoneModel> {
  @override
  final int typeId = 1;

  @override
  MilestoneModel read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return MilestoneModel(
      day: fields[0] as int,
      title: fields[1] as String,
      description: fields[2] as String,
      isCompleted: fields[3] as bool,
      completedAt: fields[4] != null ? DateTime.parse(fields[4] as String) : null,
      weatherAlertTriggered: fields[5] as bool,
      // Fields 6/7 are new — guarded with a length check so milestones
      // saved before this update (without Sinhala text) still load fine.
      titleSi: numFields > 6 ? fields[6] as String? : null,
      descriptionSi: numFields > 7 ? fields[7] as String? : null,
    );
  }

  @override
  void write(BinaryWriter writer, MilestoneModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.day)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.completedAt?.toIso8601String())
      ..writeByte(5)
      ..write(obj.weatherAlertTriggered)
      ..writeByte(6)
      ..write(obj.titleSi)
      ..writeByte(7)
      ..write(obj.descriptionSi);
  }
}
