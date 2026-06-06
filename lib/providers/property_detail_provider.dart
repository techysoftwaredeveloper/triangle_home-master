import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/providers/property_provider.dart';
import 'package:triangle_home/services/hoster_service.dart';

final propertyStatsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, propertyId) {
  final service = ref.watch(propertyServiceProvider);
  return service.getPropertyStats(propertyId);
});

final propertyRoomsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, propertyId) {
  final service = ref.watch(propertyServiceProvider);
  return service.getPropertyRooms(propertyId);
});

final propertyBedsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, propertyId) {
  final service = ref.watch(propertyServiceProvider);
  return service.getPropertyBeds(propertyId);
});

final propertyReviewsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, propertyId) {
  final service = ref.watch(propertyServiceProvider);
  return service.getPropertyReviews(propertyId);
});

final hostProfileProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, hostId) {
  return HosterService().getUserProfileStream(hostId);
});

/// Computed provider for occupancy types based on rooms
final occupancyTypesProvider = Provider.family<List<Map<String, dynamic>>, String>((ref, propertyId) {
  final roomsAsync = ref.watch(propertyRoomsProvider(propertyId));
  
  return roomsAsync.when(
    data: (rooms) {
      final Map<String, Map<String, dynamic>> summary = {};
      
      for (final room in rooms) {
        final type = room['occupancyType'] ?? 'Unknown';
        if (!summary.containsKey(type)) {
          summary[type] = {
            'name': type,
            'startingRent': room['baseRent'] ?? 0.0,
            'availableBeds': 0,
            'availableRooms': 0,
            'keyFeatures': room['amenities'] ?? [],
          };
        }
        
        summary[type]!['availableBeds'] += (room['availableBeds'] as num?)?.toInt() ?? 0;
        if (((room['availableBeds'] as num?)?.toInt() ?? 0) > 0) {
          summary[type]!['availableRooms'] += 1;
        }
        
        // Ensure we take the lowest starting rent
        if (((room['baseRent'] as num?)?.toDouble() ?? 0) < summary[type]!['startingRent']) {
          summary[type]!['startingRent'] = room['baseRent'];
        }
      }
      
      return summary.values.toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
