import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:triangle_home/models/local_user.dart';
import 'package:triangle_home/models/local_location.dart';
import 'package:triangle_home/models/admin_cache.dart';

class IsarService {
  late Future<Isar> db;

  IsarService() {
    db = openDB();
  }

  Future<Isar> openDB() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      return await Isar.open(
        [
          LocalUserSchema,
          LocalLocationSchema,
          UserLocationPreferenceSchema,
          AdminCacheSchema,
        ],
        inspector: true,
        directory: dir.path,
      );
    }
    return Isar.getInstance()!;
  }

  // Admin Cache Operations (Used for general caching including drafts)
  Future<void> saveAdminCache(String key, String jsonData) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.adminCaches.put(AdminCache(
        key: key,
        jsonData: jsonData,
        lastUpdated: DateTime.now(),
      ));
    });
  }

  Future<String?> getAdminCache(String key) async {
    final isar = await db;
    final cache = await isar.adminCaches.filter().keyEqualTo(key).findFirst();
    return cache?.jsonData;
  }

  Future<void> clearAdminCache(String key) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.adminCaches.filter().keyEqualTo(key).deleteFirst();
    });
  }

  // Legacy Property Draft wrappers using AdminCache
  Future<void> savePropertyDraft(String hosterId, String jsonData) async {
    await saveAdminCache('property_draft_$hosterId', jsonData);
  }

  Future<String?> getPropertyDraft(String hosterId) async {
    return await getAdminCache('property_draft_$hosterId');
  }

  Future<void> clearPropertyDraft(String hosterId) async {
    await clearAdminCache('property_draft_$hosterId');
  }

  // Location Cache Operations
  Future<void> saveMajorCities(List<String> cities) async {
    final isar = await db;
    await isar.writeTxn(() async {
      for (final name in cities) {
        await isar.localLocations.put(LocalLocation(cityName: name, isMajor: true));
      }
    });
  }

  Future<List<String>> getCachedMajorCities() async {
    final isar = await db;
    final results = await isar.localLocations.filter().isMajorEqualTo(true).findAll();
    return results.map((l) => l.cityName).toList();
  }

  // User Preference Cache
  Future<void> saveLocationPreference({String? selected, String? detected}) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final pref = UserLocationPreference()
        ..id = 0
        ..lastSelectedCity = selected
        ..lastDetectedCity = detected;
      await isar.userLocationPreferences.put(pref);
    });
  }

  Future<UserLocationPreference?> getLocationPreference() async {
    final isar = await db;
    return await isar.userLocationPreferences.get(0);
  }

  // User Operations
  Future<void> saveLocalUser(LocalUser user) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.localUsers.put(user);
    });
  }

  Future<LocalUser?> getLocalUser(String uid) async {
    final isar = await db;
    return await isar.localUsers.filter().uidEqualTo(uid).findFirst();
  }

  Future<void> clearAll() async {
    final isar = await db;
    await isar.writeTxn(() => isar.clear());
  }

  // Clear role-specific caches
  Future<void> clearHosterCache(String uid) async {
    await clearAdminCache('hoster_application_draft_$uid');
    await clearAdminCache('property_draft_$uid');
    await clearAdminCache('user_onboarding_intent');
  }

  // User Intent Tracking (Separates Hoster/Student flows)
  Future<void> setUserIntent(String mode) async {
    await saveAdminCache('user_onboarding_intent', mode);
  }

  Future<String?> getUserIntent() async {
    return await getAdminCache('user_onboarding_intent');
  }

  Future<void> clearUserIntent() async {
    await clearAdminCache('user_onboarding_intent');
  }
}
