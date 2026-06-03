import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_home/services/sync_service.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/models/pending_action.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([IsarService, Connectivity])
import 'sync_service_test.mocks.dart';

void main() {
  group('SyncService Offline capabilities', () {
    late MockIsarService mockIsarService;
    late MockConnectivity mockConnectivity;
    late SyncService syncService;

    setUp(() {
      mockIsarService = MockIsarService();
      mockConnectivity = MockConnectivity();

      syncService = SyncService(
        isarService: mockIsarService,
        connectivity: mockConnectivity,
      );
    });

    test('forceSync calls cleanStaleCache on IsarService', () async {
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(mockIsarService.dequeueActions()).thenAnswer((_) async => []);

      await syncService.forceSync();

      verify(mockIsarService.cleanStaleCache()).called(1);
    });

    test('forceSync processes pending actions if online', () async {
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      final action = PendingAction(
        actionId: '1',
        type: 'BOOKING_CONFIRM',
        payload: '{"some":"data"}',
        createdAt: DateTime.now(),
      )..id = 1;

      when(mockIsarService.dequeueActions()).thenAnswer((_) async => [action]);
      when(mockIsarService.removeAction(any)).thenAnswer((_) async {});

      await syncService.forceSync();

      verify(mockIsarService.dequeueActions()).called(1);
      verify(mockIsarService.removeAction(1)).called(1);
    });

    test('forceSync does not process actions if offline', () async {
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      await syncService.forceSync();

      verifyNever(mockIsarService.dequeueActions());
    });

    test('Actions exceeding retry count are ignored', () async {
      when(
        mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      final action =
          PendingAction(
              actionId: 'failed_action',
              type: 'BOOKING_CONFIRM',
              payload: '{}',
              createdAt: DateTime.now(),
            )
            ..id = 2
            ..retryCount = 6;

      when(mockIsarService.dequeueActions()).thenAnswer((_) async => [action]);

      await syncService.forceSync();

      verifyNever(mockIsarService.removeAction(2));
      verifyNever(mockIsarService.incrementActionRetry(2));
    });
  });
}
