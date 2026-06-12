import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_home/widgets/logout_confirmation_dialog.dart';

void main() {
  testWidgets('LogoutConfirmationDialog renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogoutConfirmationDialog(
            onConfirm: () {},
          ),
        ),
      ),
    );

    // Let layout animations complete to clear pending timers
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sign Out'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to log out of Triangle Homes? You will need to verify your phone again to sign back in.',
      ),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
  });

  testWidgets('LogoutConfirmationDialog calls onConfirm when Log Out is tapped', (WidgetTester tester) async {
    bool didConfirm = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LogoutConfirmationDialog(
            onConfirm: () {
              didConfirm = true;
            },
          ),
        ),
      ),
    );

    // Let layout animations complete to clear pending timers
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Log Out'));
    await tester.pump();

    expect(didConfirm, isTrue);
  });
}
