import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_home/widgets/list_property/progress_bar.dart';
import 'package:triangle_home/widgets/property_managment/property_card.dart';

void main() {
  group('Dashboard & Wizard Widget Tests', () {
    testWidgets('ProgressBar renders correct number of steps and title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ProgressBar(currentStep: 2, totalSteps: 9)),
        ),
      );

      // Should show 'Step 3 of 9' (since currentStep is 0-indexed)
      expect(find.text('Step 3 of 9'), findsOneWidget);

      // Step 2 corresponds to 'Property Details' (0-indexed: index 2 is step 3)
      expect(find.text('Property Details'), findsOneWidget);
    });

    testWidgets('PropertyCard renders property details correctly', (
      WidgetTester tester,
    ) async {
      final mockProperty = {
        'title': 'Test Hostel',
        'address': '123 Test St',
        'status': 'Active',
        'type': 'Hostel',
        'rooms': 10,
        'listed': '01 Jan 2026',
        'image':
            'https://via.placeholder.com/150', // CachedNetworkImage will try to load this, but in tests it fails safely
      };

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: PropertyCard(property: mockProperty))),
      );

      expect(find.text('Test Hostel'), findsOneWidget);
      expect(find.text('123 Test St'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Hostel'), findsOneWidget);
      expect(find.text('10 Rooms'), findsOneWidget);
      expect(find.text('Listed on: 01 Jan 2026'), findsOneWidget);
    });
  });
}
