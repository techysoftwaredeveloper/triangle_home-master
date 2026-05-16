import 'package:isar/isar.dart';

part 'local_location.g.dart';

@collection
class LocalLocation {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String cityName;

  String? stateName;
  bool isMajor = false;
  DateTime lastUpdated = DateTime.now();

  LocalLocation({
    required this.cityName,
    this.stateName,
    this.isMajor = false,
  });
}

@collection
class UserLocationPreference {
  Id id = 0; // Singleton record

  String? lastSelectedCity;
  String? lastDetectedCity;
  DateTime lastSync = DateTime.now();
}
