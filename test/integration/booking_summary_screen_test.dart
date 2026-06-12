import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_home/screens/booking_summary_screen.dart';
import 'package:triangle_home/theme/app_theme.dart';

void main() {
  testWidgets('BookingSummaryScreen displays correct prices and calculations', (WidgetTester tester) async {
    final accommodation = {
      'id': 'test_prop_1',
      'title': 'Premium PG Bangalore',
      'location': 'Koramangala, Bangalore',
      'type': 'PG Accommodation',
      'monthlyRent': 10000.0,
      'securityDeposit': 5000.0,
      'image': 'https://example.com/image1.jpg',
    };

    final tenantDetails = [
      {
        'name': 'Primary Tenant',
        'phone': '1234567890',
        'email': 'tenant@example.com',
        'college': 'My College',
      }
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          primaryColor: AppTheme.primaryColor,
        ),
        home: BookingSummaryScreen(
          accommodation: accommodation,
          tenantDetails: tenantDetails,
          tenants: const [],
          tenantCount: 1,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Check Property Details
    expect(find.text('Premium PG Bangalore'), findsOneWidget);
    expect(find.text('Koramangala, Bangalore'), findsOneWidget);

    // Check Tenant Details
    expect(find.text('Tenant 1'), findsOneWidget);
    expect(find.text('Name: '), findsOneWidget);
    expect(find.text('Primary Tenant'), findsOneWidget);

    // Check Payment Summary
    // Monthly Rent
    expect(find.text('Monthly Rent (per tenant)'), findsOneWidget);
    expect(find.text('₹10000'), findsNWidgets(2)); // Once for per tenant, once for total monthly rent

    // Number of Tenants
    expect(find.text('Number of Tenants'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Total Monthly Rent
    expect(find.text('Total Monthly Rent'), findsOneWidget);

    // Security Deposit
    expect(find.text('Security Deposit'), findsOneWidget);
    expect(find.text('₹5000'), findsOneWidget);

    // Total Amount (10000 + 5000 = 15000)
    expect(find.text('Total Amount'), findsOneWidget);
    expect(find.text('₹15000'), findsOneWidget);

    // Check Button
    expect(find.text('Proceed to Payment'), findsOneWidget);
  });
}
