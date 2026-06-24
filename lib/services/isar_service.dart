import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:triangle_home/models/local_user.dart';
import 'package:triangle_home/models/local_location.dart';
import 'package:triangle_home/models/admin_cache.dart';
import 'package:triangle_home/models/pending_action.dart';
import 'package:triangle_home/models/cached_search_result.dart';

class IsarService {
  static final IsarService instance = IsarService._internal();
  late Future<Isar> db;
  bool _isInitialized = false;

  IsarService._internal() {
    db = openDB();
  }

  factory IsarService() => instance;

  Future<Isar> openDB() async {
    if (_isInitialized) return Isar.getInstance()!;

    final dir = await getApplicationDocumentsDirectory();
    final isar = await Isar.open(
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
    _isInitialized = true;
    return isar;
  }

  // --- Generic Cache Core ---

  Future<void> cacheData(String key, String data, {Duration? ttl}) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.adminCaches.put(
        AdminCache(
          key: key,
          jsonData: data,
          lastUpdated: DateTime.now(),
          expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
        ),
      );
    });
  }

  Future<String?> getCachedData(String key) async {
    final isar = await db;
    final cache = await isar.adminCaches.filter().keyEqualTo(key).findFirst();

    if (cache != null &&
        cache.expiresAt != null &&
        cache.expiresAt!.isBefore(DateTime.now())) {
      await isar.writeTxn(() async {
        await isar.adminCaches.filter().keyEqualTo(key).deleteFirst();
      });
      return null;
    }
    return cache?.jsonData;
  }

  /// Aliases for backward compatibility
  Future<void> saveAdminCache(String key, String jsonData, {Duration? ttl}) => 
    cacheData(key, jsonData, ttl: ttl);

  Future<String?> getAdminCache(String key) => getCachedData(key);

  /// Loads from cache first, then executes [remoteFetcher] and updates cache.
  Stream<String> getWithRevalidate({
    required String key,
    required Future<String> Function() remoteFetcher,
  }) async* {
    final cached = await getCachedData(key);
    if (cached != null) {
      yield cached;
    }

    try {
      final fresh = await remoteFetcher();
      await cacheData(key, fresh);
      yield fresh;
    } catch (e) {
      debugPrint('Revalidation failed for $key: $e');
    }
  }

  // --- User Module Cache ---
  Future<void> cacheUserProfile(String uid, String jsonData) async {
    await cacheData('user_profile_$uid', jsonData, ttl: const Duration(days: 1));
  }

  Future<String?> getCachedUserProfile(String uid) async {
    return await getCachedData('user_profile_$uid');
  }

  // --- Hoster Module Cache ---
  Future<void> cacheHosterProperties(String hosterId, String jsonData) async {
    await cacheData('hoster_props_$hosterId', jsonData, ttl: const Duration(hours: 4));
  }

  Future<String?> getCachedHosterProperties(String hosterId) async {
    return await getCachedData('hoster_props_$hosterId');
  }

  // --- Admin Module Cache ---
  Future<void> cacheAdminStats(String jsonData) async {
    await cacheData('admin_dashboard_stats', jsonData, ttl: const Duration(minutes: 30));
  }

  Future<String?> getCachedAdminStats() async {
    return await getCachedData('admin_dashboard_stats');
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
    await cacheData(
      'draft_${type}_$id',
      jsonData,
      ttl: const Duration(days: 7),
    );
  }

  Future<String?> getDraft(String type, String id) async {
    return await getCachedData('draft_${type}_$id');
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
    await cacheData(
      'property_draft_$hosterId',
      jsonData,
      ttl: const Duration(days: 30),
    );
  }

  Future<String?> getPropertyDraft(String hosterId) async {
    return await getCachedData('property_draft_$hosterId');
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
    await cacheData(
      'user_onboarding_intent',
      mode,
      ttl: const Duration(hours: 24),
    );
  }

  Future<String?> getUserIntent() async {
    return await getCachedData('user_onboarding_intent');
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
