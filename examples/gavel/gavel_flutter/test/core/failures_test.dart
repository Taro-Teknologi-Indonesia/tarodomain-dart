import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_flutter/core/failures.dart';

void main() {
  test('a 401 is SignedOut (X6)', () {
    expect(GavelFailure.from(ServerpodClientUnauthorized()), isA<SignedOut>());
  });
}
