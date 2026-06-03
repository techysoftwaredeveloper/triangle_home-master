import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:mockito/mockito.dart';

import '../unit/hoster_stats_test.mocks.dart';

void main() {
  group('Integration - Draft Recovery Flow', () {
    late MockIsarService mockIsarService;

    setUp(() {
      mockIsarService = MockIsarService();
    });

    test('Property wizard seamlessly recovers draft from Isar', () async {
      final userUid = 'test_user_123';

      // 1. Simulate saving a draft in Isar
      final savedDraft = {
        'hostProfile': {'name': 'Test User', 'hostType': 'Owner'},
        'last_step': 2,
      };

      when(
        mockIsarService.savePropertyDraft(userUid, any),
      ).thenAnswer((_) async {});
      when(
        mockIsarService.getPropertyDraft(userUid),
      ).thenAnswer((_) async => jsonEncode(savedDraft));

      // 2. Fetch it back (simulating app restart)
      final recoveredDraftStr = await mockIsarService.getPropertyDraft(userUid);
      expect(recoveredDraftStr, isNotNull);

      final recoveredDraft = jsonDecode(recoveredDraftStr!);

      // 3. Verify the state is correctly restored
      expect(recoveredDraft['last_step'], equals(2));
      expect(recoveredDraft['hostProfile']['name'], equals('Test User'));
    });

    test('Draft cleared upon submission', () async {
      final userUid = 'test_user_123';

      when(
        mockIsarService.clearPropertyDraft(userUid),
      ).thenAnswer((_) async {});

      // Simulate submission clear
      await mockIsarService.clearPropertyDraft(userUid);

      verify(mockIsarService.clearPropertyDraft(userUid)).called(1);
    });
  });
}
