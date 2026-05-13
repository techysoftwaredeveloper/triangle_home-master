import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/services/booking_service.dart';

final bookingServiceProvider = Provider((ref) => BookingService());

// Add more providers for booking state management as needed
