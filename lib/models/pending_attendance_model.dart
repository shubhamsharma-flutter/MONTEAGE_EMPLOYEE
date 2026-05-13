import 'package:hive/hive.dart';

part 'pending_attendance_model.g.dart';

@HiveType(typeId: 0)
class PendingAttendanceModel extends HiveObject {
  @HiveField(0)
  String type; // 'checkin' or 'checkout'

  @HiveField(1)
  String latitude;

  @HiveField(2)
  String longitude;

  @HiveField(3)
  String imagePath;

  

  @HiveField(5)
  DateTime savedAt;

  PendingAttendanceModel({
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.imagePath,
   
    required this.savedAt,
  });
}