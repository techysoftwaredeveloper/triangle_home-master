import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:triangle_home/models/local_user.dart';
import 'package:triangle_home/models/local_location.dart';
import 'package:triangle_home/models/admin_cache.dart';
import 'package:triangle_home/models/pending_action.dart';
import 'package:triangle_home/models/cached_search_result.dart';

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
          PendingActionSchema,
          CachedSearchResultSchema,
        ],
        inspector: true,
        directory: dir.path,
      );
    }
    return Isar.getInstance()!;
  }

  // Admin Cache Operations (Used for general caching including drafts)
  Future<void> saveAdminCache(
    String key,
    String jsonData, {
    Duration? ttl,
  }) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.adminCaches.put(
        AdminCache(
          key: key,
          jsonData: jsonData,
          lastUpdated: DateTime.now(),
          expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
        ),
      );
    });
  }

  Future<String?> getAdminCache(String key) async {
    final isar = await db;
    final cache = await isar.adminCaches.filter().keyEqualTo(key).findFirst();

    if (cache != null &&
        cache.expiresAt != null &&
        cache.expiresAt!.isBefore(DateTime.now())) {
      // Expired
      await isar.writeTxn(() async {
        await isar.adminCaches.filter().keyEqualTo(key).deleteFirst();
      });
      return null;
    }

    return cache?.jsonData;
  }

  Future<void> clearAdminCache(String key) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.adminCaches.filter().keyEqualTo(key).deleteFirst();
    });
  }

  Future<void> cleanStaleCache() async {
    final isar = await db;
    final now = DateTime.now();
    await isar.writeTxn(() async {
      await isar.adminCaches.filter().expiresAtLessThan(now).deleteAll();
      await isar.cachedSearchResults
          .filter()
          .expiresAtLessThan(now)
          .deleteAll();
    });
  }

  // Generic Draft Operations
  Future<void> saveDraft(String type, String id, String jsonData) async {
    await saveAdminCache(
      'draft_${type}_$id',
      jsonData,
      ttl: const Duration(days: 7),
    );
  }

  Future<String?> getDraft(String type, String id) async {
    return await getAdminCache('draft_${type}_$id');
  }

  Future<void> clearDraft(String type, String id) async {
    await clearAdminCache('draft_${type}_$id');
  }

  // Maintenance Draft Wrappers
  Future<void> saveMaintenanceDraft(String residentId, String jsonData) async {
    await saveDraft('maintenance', residentId, jsonData);
  }

  Future<String?> getMaintenanceDraft(String residentId) async {
    return await getDraft('maintenance', residentId);
  }

  Future<void> clearMaintenanceDraft(String residentId) async {
    await clearDraft('maintenance', residentId);
  }

  // Legacy Property Draft wrappers using AdminCache
  Future<void> savePropertyDraft(String hosterId, String jsonData) async {
    await saveAdminCache(
      'property_draft_$hosterId',
      jsonData,
      ttl: const Duration(days: 30),
    );
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
        await isar.localLocations.put(
          LocalLocation(cityName: name, isMajor: true),
        );
      }
    });
  }

  Future<List<String>> getCachedMajorCities() async {
    final isar = await db;
    final results =
        await isar.localLocations.filter().isMajorEqualTo(true).findAll();
    return results.map((l) => l.cityName).toList();
  }

  // User Preference Cache
  Future<void> saveLocationPreference({
    String? selected,
    String? detected,
  }) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final pref =
          UserLocationPreference()
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
    await saveAdminCache(
      'user_onboarding_intent',
      mode,
      ttl: const Duration(hours: 24),
    );
  }

  Future<String?> getUserIntent() async {
    return await getAdminCache('user_onboarding_intent');
  }

  Future<void> clearUserIntent() async {
    await clearAdminCache('user_onboarding_intent');
  }

  // --- Offline Action Queue ---

  Future<void> enqueueAction(
    String actionId,
    String type,
    String payload,
  ) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.pendingActions.put(
        PendingAction(
          actionId: actionId,
          type: type,
          payload: payload,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Future<List<PendingAction>> dequeueActions() async {
    final isar = await db;
    return await isar.pendingActions.where().sortByCreatedAt().findAll();
  }

  Future<void> removeAction(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.pendingActions.delete(id);
    });
  }

  Future<void> incrementActionRetry(int id) async {
    final isar = await db;
    final action = await isar.pendingActions.get(id);
    if (action != null) {
      action.retryCount += 1;
      await isar.writeTxn(() async {
        await isar.pendingActions.put(action);
      });
    }
  }

  // --- Search Result Cache ---

  Future<void> saveSearchResult(
    String queryKey,
    List<String> propertyIds, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.cachedSearchResults.put(
        CachedSearchResult(
          queryKey: queryKey,
          propertyIds: propertyIds,
          expiresAt: DateTime.now().add(ttl),
        ),
      );
    });
  }

  Future<List<String>?> getSearchResult(String queryKey) async {
    final isar = await db;
    final cache =
        await isar.cachedSearchResults
            .filter()
            .queryKeyEqualTo(queryKey)
            .findFirst();

    if (cache != null && cache.expiresAt.isBefore(DateTime.now())) {
      // Expired
      await isar.writeTxn(() async {
        await isar.cachedSearchResults
            .filter()
            .queryKeyEqualTo(queryKey)
            .deleteFirst();
      });
      return null;
    }

    return cache?.propertyIds;
  }
}
