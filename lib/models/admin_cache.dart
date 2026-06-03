import 'package:isar/isar.dart';

part 'admin_cache.g.dart';

@collection
class AdminCache {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String key; // e.g., 'all_users', 'total_revenue', 'approvals_list'

  String? jsonData; // JSON string of the cached data
  DateTime? lastUpdated;
  DateTime? expiresAt; // For TTL support

  AdminCache({
    required this.key,
    this.jsonData,
    this.lastUpdated,
    this.expiresAt,
  });
}
