import 'package:isar/isar.dart';

part 'local_cache.g.dart';

@collection
class LocalCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String key;

  String? jsonData;
  DateTime? lastUpdated;
  DateTime? expiresAt;

  LocalCache({
    required this.key,
    this.jsonData,
    this.lastUpdated,
    this.expiresAt,
  });
}
