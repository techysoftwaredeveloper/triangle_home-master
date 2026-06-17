import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:triangle_home/core/constants/enums.dart';
import 'package:triangle_home/services/isar_service.dart';
import 'package:triangle_home/models/pending_action.dart';
import 'package:triangle_home/services/maintenance_service.dart';
import 'package:triangle_home/services/booking_service.dart';
import 'package:triangle_home/services/payment_service.dart';


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
      final payloadData = json.decode(action.payload);

      switch (action.type) {
        case 'BOOKING_CONFIRM':
          final bs = BookingService();
          await bs.updateBookingStatus(
            payloadData['bookingId'],
            BookingStatus.values.firstWhere(
              (e) => e.name == payloadData['status'],
              orElse: () => BookingStatus.bookingConfirmed,
            ),
            reason: payloadData['reason'],
            performerId: payloadData['performerId'],
          );
          debugPrint('SyncService: Processing offline BOOKING_CONFIRM');
          return true;

        case 'PAYMENT_VERIFY':
          final ps = PaymentService();
          await ps.recordPayment(
            bookingId: payloadData['bookingId'],
            requestId: payloadData['requestId'],
            amount: payloadData['amount']?.toDouble() ?? 0.0,
            type: PaymentType.values.firstWhere(
              (e) => e.name == payloadData['type'],
              orElse: () => PaymentType.other,
            ),
            paymentMethod: payloadData['paymentMethod'],
            extraData: payloadData['extraData'],
          );
          debugPrint('SyncService: Processing offline PAYMENT_VERIFY');
          return true;

        case 'MAINTENANCE_CREATE':
          final ms = MaintenanceService();
          await ms.createTicket(
            residentId: payloadData['residentId'],
            stayId: payloadData['stayId'],
            title: payloadData['title'],
            description: payloadData['description'],
            category: TicketCategory.values.firstWhere(
              (e) => e.name == payloadData['category'],
              orElse: () => TicketCategory.other,
            ),
            priority: TicketPriority.values.firstWhere(
              (e) => e.name == payloadData['priority'],
              orElse: () => TicketPriority.low,
            ),
          );
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
