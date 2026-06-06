import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triangle_home/screens/property_detail_screen_v2.dart';
import 'package:triangle_home/providers/property_detail_provider.dart';
import 'package:triangle_home/widgets/property_detail_v2/sticky_booking_bar.dart';

void main() {
  testWidgets('PropertyDetailScreenV2 renders correctly and handles bed selection', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    final property = {
      'id': 'test_prop_1',
      'title': 'Premium PG Bangalore',
      'location': 'Koramangala, Bangalore',
      'rating': 4.5,
      'reviewCount': 120,
      'verified': true,
      'images': ['https://example.com/image1.jpg'],
      'hoster_id': 'host_1',
      'amenities': ['WiFi', 'AC'],
    };

    final stats = {
      'availableBeds': 5,
      'availableRooms': 2,
      'updatedAt': null,
    };

    final rooms = [
      {
        'id': 'room_1',
        'roomNumber': '101',
        'occupancyType': 'Double Sharing',
        'baseRent': 10000.0,
        'availableBeds': 1,
        'images': ['https://example.com/room1.jpg'],
      }
    ];

    final beds = [
      {
        'id': 'bed_1',
        'roomId': 'room_1',
        'bedNumber': 'A',
        'status': 'available',
        'monthlyRent': 10000.0,
        'securityDeposit': 5000.0,
      }
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          propertyStatsProvider('test_prop_1').overrideWith((_) => Stream.value(stats)),
          propertyRoomsProvider('test_prop_1').overrideWith((_) => Stream.value(rooms)),
          propertyBedsProvider('test_prop_1').overrideWith((_) => Stream.value(beds)),
          hostProfileProvider('host_1').overrideWith((_) => Stream.value({})),
        ],
        child: MaterialApp(
          home: PropertyDetailScreenV2(property: property),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Premium PG Bangalore'), findsOneWidget);

    // Find and tap on Room 101 row
    final roomFinder = find.text('Room 101');
    await tester.dragUntilVisible(
      roomFinder,
      find.byType(CustomScrollView),
      const Offset(0, -200),
    );
    await tester.pumpAndSettle();
    await tester.tap(roomFinder);
    await tester.pumpAndSettle();

    // Find and tap on Bed A
    final bedFinder = find.text('Bed A');
    await tester.tap(bedFinder);
    await tester.pumpAndSettle();

    // Verify StickyBookingBar updates
    expect(find.text('Room 101 - Bed A'), findsOneWidget);
    expect(find.descendant(
      of: find.byType(StickyBookingBar),
      matching: find.text('₹10000.0'),
    ), findsOneWidget);
    expect(find.text('Book This Bed'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
