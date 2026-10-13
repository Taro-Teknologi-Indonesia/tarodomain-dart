import 'package:gavel_server/src/domain/keys.dart';
import 'package:test/test.dart';

void main() {
  group('winnerCode', () {
    final keyHash = hashKey('budi-secret');
    const pirus = '0199e5a0-0000-7000-8000-000000000001';
    const juniper = '0199e5a0-0000-7000-8000-000000000002';

    test('is 6 Crockford base32 characters as XXX-XXX', () {
      expect(
        winnerCode(keyHash, pirus),
        matches(RegExp(r'^[0-9A-HJKMNP-TV-Z]{3}-[0-9A-HJKMNP-TV-Z]{3}$')),
      );
    });

    test('is the same for the same key and lot', () {
      expect(winnerCode(keyHash, pirus), winnerCode(keyHash, pirus));
    });

    test('differs for another lot or another key', () {
      final code = winnerCode(keyHash, pirus);
      expect(winnerCode(keyHash, juniper), isNot(code));
      expect(winnerCode(hashKey('other-budi-secret'), pirus), isNot(code));
    });
  });
}
