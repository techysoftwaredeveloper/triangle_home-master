import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([IsarService])
import 'hoster_stats_test.mocks.dart';

void main() {
  group('HosterService - Detailed Stats', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockIsarService mockIsarService;
    late HosterService hosterService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockIsarService = MockIsarService();

      // Mock the Isar cache so it returns null (forcing Firestore reads)
      when(mockIsarService.getAdminCache(any)).thenAnswer((_) async => null);
      when(mockIsarService.saveAdminCache(any, any)).thenAnswer((_) async {});

      hosterService = HosterService(
        firestore: fakeFirestore,
        isarService: mockIsarService,
      );
    });

    test('calculates monthly revenue correctly (Payments - Refunds)', () async {
      final now = DateTime.now();

      // 1. Successful payment
      await fakeFirestore.collection('payments').add({
        'hoster_id': 'hoster_1',
        'amount': 15000,
        'createdAt': now,
        'type': 'rent',
      });

      // 2. Refund (negative amount)
      await fakeFirestore.collection('payments').add({
        'hoster_id': 'hoster_1',
        'amount': -5000,
        'createdAt': now,
        'type': 'refund',
      });

      // 3. Payment from last month (should be ignored)
      await fakeFirestore.collection('payments').add({
        'hoster_id': 'hoster_1',
        'amount': 20000,
        'createdAt': DateTime(now.year, now.month - 1, 15),
        'type': 'rent',
      });

      // Dummy user doc to prevent null errors
      await fakeFirestore.collection('users').doc('hoster_1').set({
        'hosterRole': 'Owner',
      });

      final stream = hosterService.getDetailedHosterStatsStream('hoster_1');
      final stats = await stream.first;

      expect(stats['monthlyRevenue'], equals(10000));
    });

    test('calculates occupancy and vacant beds correctly', () async {
      // 2 Properties with total 10 capacity
      await fakeFirestore.collection('properties').add({
        'hoster_id': 'hoster_1',
        'status': 'approved',
        'propertyDetails': {'totalCapacity': 6, 'totalRooms': 3},
      });
      await fakeFirestore.collection('properties').add({
        'hoster_id': 'hoster_1',
        'status': 'approved',
        'propertyDetails': {'totalCapacity': 4, 'totalRooms': 2},
      });

      // 3 Active Residents
      await fakeFirestore.collection('bookings').add({
        'hoster_id': 'hoster_1',
        'status': 'confirmed',
      });
      await fakeFirestore.collection('bookings').add({
        'hoster_id': 'hoster_1',
        'status': 'active',
      });
      await fakeFirestore.collection('bookings').add({
        'hoster_id': 'hoster_1',
        'status': 'checkedin',
      });

      // 1 Pending booking (should not count as active resident)
      await fakeFirestore.collection('bookings').add({
        'hoster_id': 'hoster_1',
        'status': 'pending',
      });

      await fakeFirestore.collection('users').doc('hoster_1').set({
        'hosterRole': 'Owner',
      });

      final stream = hosterService.getDetailedHosterStatsStream('hoster_1');
      final stats = await stream.first;

      expect(stats['totalCapacity'], equals(10));
      expect(stats['activeResidents'], equals(3));
      expect(stats['vacantBeds'], equals(7));
      expect(stats['occupancy'], equals(30)); // (3/10) * 100
    });

    test('calculates profile completion correctly', () async {
      // Full profile setup
      await fakeFirestore.collection('users').doc('hoster_1').set({
        'info': {
          'name': 'John',
          'email': 'john@test.com',
          // Phone is missing
        },
        'verification': {
          'govIdVerified': true,
          // panVerified is missing
        },
        'host_preferences': {'rules': 'none'},
        'bank_info': {'acc': '123'},
      });

      // Fields filled: name, email, host_preferences, govIdVerified, bank_info = 5/8 fields
      // Total fields = 8

      final stream = hosterService.getDetailedHosterStatsStream('hoster_1');
      final stats = await stream.first;

      expect(stats['profileCompletion'], equals(5 / 8));
    });
  });
}
