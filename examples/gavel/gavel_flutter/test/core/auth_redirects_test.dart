import 'package:flutter_test/flutter_test.dart';
import 'package:gavel_flutter/core/auth_redirects.dart';

void main() {
  group('/new', () {
    test('signed out goes to sign in, remembering /new', () {
      expect(requireSignIn(false, Uri.parse('/new')), '/sign-in?from=%2Fnew');
    });

    test('signed in stays', () {
      expect(requireSignIn(true, Uri.parse('/new')), isNull);
    });
  });

  group('/sign-in', () {
    test('signed in goes on to where the organizer was going', () {
      expect(leaveSignIn(true, Uri.parse('/sign-in?from=%2Fnew')), '/new');
    });

    test('signed in with no from goes to /new', () {
      expect(leaveSignIn(true, Uri.parse('/sign-in')), '/new');
    });

    test('signed in never leaves for another site', () {
      for (final from in [
        '//evil.example',
        'https://evil.example',
        r'/\evil',
      ]) {
        expect(
          leaveSignIn(
            true,
            Uri(path: '/sign-in', queryParameters: {'from': from}),
          ),
          '/new',
          reason: from,
        );
      }
    });

    test('signed out stays', () {
      expect(leaveSignIn(false, Uri.parse('/sign-in?from=%2Fnew')), isNull);
    });
  });
}
