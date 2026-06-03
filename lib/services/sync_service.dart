import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/models/pending_action.dart';

class SyncService {
  final IsarService _isarService;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _cacheCleanupTimer;
  bool _isProcessing = false;

  SyncService({IsarService? isarService, Connectivity? connectivity})
    : _isarService = isarService ?? IsarService(),
      _connectivity = connectivity ?? Connectivity();

  void initialize() {
    // Monitor network changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        _processPendingActions();
      }
    });

    // Run cache cleanup every hour
    _cacheCleanupTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _isarService.cleanStaleCache();
    });

    // Initial cleanup on boot
    _isarService.cleanStaleCache();

    // Initial process attempt
    _checkAndProcess();
  }

  Future<void> _checkAndProcess() async {
    final results = await _connectivity.checkConnectivity();
    final isOnline = results.any((r) => r != ConnectivityResult.none);
    if (isOnline) {
      await _processPendingActions();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _cacheCleanupTimer?.cancel();
  }

  Future<void> _processPendingActions() async {
    if (_isProcessing) return;

    final actions = await _isarService.dequeueActions();
    if (actions.isEmpty) return;

    _isProcessing = true;

    try {
      for (final action in actions) {
        if (action.retryCount > 5) {
          // Dead letter queue / manual intervention required, or just log
          debugPrint(
            'SyncService: Action ${action.id} failed 5 times. Ignoring.',
          );
          continue;
        }

        bool success = await _executeAction(action);
        if (success) {
          await _isarService.removeAction(action.id);
        } else {
          await _isarService.incrementActionRetry(action.id);
        }
      }
    } catch (e) {
      debugPrint('SyncService: Error processing actions: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _executeAction(PendingAction action) async {
    try {
      final payload = json.decode(action.payload);

      switch (action.type) {
        case 'BOOKING_CONFIRM':
          // TODO: Inject BookingService and process booking
          debugPrint('SyncService: Processing offline BOOKING_CONFIRM');
          return true;

        case 'PAYMENT_VERIFY':
          // TODO: Process payment
          debugPrint('SyncService: Processing offline PAYMENT_VERIFY');
          return true;

        case 'MAINTENANCE_CREATE':
          // TODO: Inject MaintenanceService and process ticket
          debugPrint('SyncService: Processing offline MAINTENANCE_CREATE');
          return true;

        default:
          debugPrint('SyncService: Unknown action type ${action.type}');
          return false; // Don't remove, might be handled by newer app version
      }
    } catch (e) {
      debugPrint('SyncService: Action execution failed: $e');
      return false;
    }
  }

  // Expose a way to manually trigger sync
  Future<void> forceSync() async {
    await _checkAndProcess();
    await _isarService.cleanStaleCache();
  }
}
