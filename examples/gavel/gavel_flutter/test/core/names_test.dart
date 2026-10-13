import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/core/names.dart';

import '../support.dart';

void main() {
  test('nameTag uses the last 4 hex characters, not the leading '
      'timestamp', () {
    final id = UuidValue.fromString('0199e5a0-1c2d-7abc-8def-0123456f3f9c');
    expect(nameTag(id), '#3f9c');
  });

  test('a name two participants share is tagged, trimmed and '
      'case-insensitive', () {
    final shared = sharedNames([('Budi', budi), (' budi ', otherBudi)]);

    expect(displayName('Budi', budi, shared), 'Budi · #00b1');
    expect(displayName('budi', otherBudi, shared), 'budi · #00b2');
  });

  test('a name only one participant goes by stays plain', () {
    final shared = sharedNames([('Siti', siti), ('Siti', siti)]);

    expect(shared, isEmpty);
    expect(displayName('Siti', siti, shared), 'Siti');
  });
}
