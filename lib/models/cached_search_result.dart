import 'package:isar/isar.dart';

part 'cached_search_result.g.dart';

@collection
class CachedSearchResult {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  String queryKey; // e.g., 'Kochi_5000_10000_male_double'

  List<String> propertyIds;
  DateTime expiresAt;

  CachedSearchResult({
    required this.queryKey,
    required this.propertyIds,
    required this.expiresAt,
  });
}
