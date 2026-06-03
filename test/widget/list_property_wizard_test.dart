import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_home/screens/list_property/host_profile_step.dart';

void main() {
  group('List Property Wizard Widget Tests', () {
    testWidgets('HostProfileStep validates required fields', (
      WidgetTester tester,
    ) async {
      bool didContinue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HostProfileStep(
              onContinue: (data) {
                didContinue = true;
              },
            ),
          ),
        ),
      );

      // Try to submit empty form
      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(didContinue, isFalse);
    });

    testWidgets('HostProfileStep submits correct data', (
      WidgetTester tester,
    ) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HostProfileStep(
              onContinue: (data) {
                submittedData = data;
              },
            ),
          ),
        ),
      );

      // Fill in text fields
      final textFields = find.byType(TextFormField);

      await tester.enterText(textFields.at(0), 'John Doe'); // Name
      await tester.enterText(textFields.at(1), 'john@example.com'); // Email
      await tester.enterText(textFields.at(2), '9876543210'); // Phone

      // Select 'Hostel Operator'
      await tester.ensureVisible(find.text('Hostel Operator'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hostel Operator'));
      await tester.pumpAndSettle();

      // Submit
      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
      final profile = submittedData!['hostProfile'];
      expect(profile['name'], 'John Doe');
      expect(profile['email'], 'john@example.com');
      expect(profile['phone'], '9876543210');
      expect(profile['hostType'], 'Hostel Operator');
    });
  });
}
