import 'package:flutter_test/flutter_test.dart';
import 'package:triangle_home/core/errors/failures.dart';

void main() {
  group('Failures', () {
    test('should return correct string representation', () {
      const failure = Failure('Test message', code: 'TEST_CODE');
      expect(
        failure.toString(),
        'Failure(code: TEST_CODE, message: Test message)',
      );
    });

    test('BookingFailure should have correct default code', () {
      const failure = BookingFailure('Room full');
      expect(failure.code, 'BOOKING_ERROR');
    });
  });
}
