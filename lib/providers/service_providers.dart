import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/services/property_service.dart';
import 'package:triangle_home/services/booking_service.dart';
import 'package:triangle_home/services/payment_service.dart';
import 'package:triangle_home/services/hoster_service.dart';
import 'package:triangle_home/services/admin_service.dart';
import 'package:triangle_home/services/app_search_service.dart';

final propertyServiceProvider = Provider((ref) => PropertyService());
final bookingServiceProvider = Provider((ref) => BookingService());
final paymentServiceProvider = Provider((ref) => PaymentService());
final hosterServiceProvider = Provider((ref) => HosterService());
final adminServiceProvider = Provider((ref) => AdminService());
final searchServiceProvider = Provider<AppSearchService>(
  (ref) => ApiSearchService(),
);
