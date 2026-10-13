import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('AggregateId', () {
    test('generate creates distinct UUIDv7s', () {
      final a = AccountId.generate();
      final b = AccountId.generate();
      expect(a, isNot(b));
      expect(a.value.isV7, isTrue);
      expect(AccountId.fromUuidv7(a.uuid), a);
    });

    test('fromExisting accepts any version and normalizes case', () {
      final id = AccountId.fromExisting(v4.toUpperCase());
      expect(id.uuid, v4);
      expect(id, AccountId.fromExisting(v4));
      expect(id.toString(), v4);
    });

    test('fromUuidv7 accepts only version 7', () {
      expect(AccountId.fromUuidv7(v7).uuid, v7);
      expect(
        () => AccountId.fromUuidv7(v4),
        throwsA(isA<ValueObjectInvalidError>()),
      );
      expect(
        () => AccountId.fromUuidv7('ffffffff-ffff-ffff-ffff-ffffffffffff'),
        throwsA(isA<ValueObjectInvalidError>()),
      );
    });

    test('rejects malformed input', () {
      for (final input in [
        '',
        'not-a-uuid',
        '${v4}0',
        v4.replaceAll('-', ''),
      ]) {
        expect(
          () => AccountId.fromExisting(input),
          throwsA(isA<ValueObjectInvalidError>()),
          reason: input,
        );
      }
    });

    test('IDs of different aggregate types are never equal', () {
      expect(AccountId.fromExisting(v4), isNot(TransferId.fromExisting(v4)));
    });
  });
}
