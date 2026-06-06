import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:triangle_home/services/sync_service.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../unit/hoster_stats_test.mocks.dart';
import '../unit/sync_service_test.mocks.dart' hide MockIsarService;

void main() {
  group('Integration - Property Creation & Sync Flow', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockIsarService mockIsarService;
    late MockConnectivity mockConnectivity;
    late SyncService syncService;
    late HosterService hosterService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockIsarService = MockIsarService();
      mockConnectivity = MockConnectivity();

      syncService = SyncService(
        isarService: mockIsarService,
        connectivity: mockConnectivity,
      );

      hosterService = HosterService(
        firestore: fakeFirestore,
        isarService: mockIsarService,
      );

      when(mockIsarService.getAdminCache(any)).thenAnswer((_) async => null);
      when(mockIsarService.saveAdminCache(any, any)).thenAnswer((_) async {});
    });

    test('Property Creation updates dashboard stats successfully', () async {
      // 1. Simulate property creation directly into Firestore (simulating the UI submit)
      await fakeFirestore.collection('properties').add({
        'hoster_id': 'hoster_1',
        'status': 'approved',
        'propertyDetails': {'totalCapacity': 15, 'totalRooms': 5},
      });

      // 2. Add an offline booking confirm action
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      // (This tests that sync service runs without crashing in integration)
      when(mockIsarService.dequeueActions()).thenAnswer((_) async => []);

      await syncService.forceSync();

      // 3. Verify Hoster Stats see the new property
      await fakeFirestore.collection('users').doc('hoster_1').set({
        'hosterRole': 'Owner',
      });

      final stream = hosterService.getDetailedHosterStatsStream('hoster_1');
      final stats = await stream.first;

      // Stats should reflect 1 active listing and 15 capacity
      expect(stats['activeListings'], equals(1));
      expect(stats['totalCapacity'], equals(15));
      expect(stats['totalProperties'], equals(1));
    });
  });
}
