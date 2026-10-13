import 'test_tools/serverpod_test_tools.dart';

/// The auth user identifier of the organizer in [signedIn] sessions.
const organizerUserId = 'organizer-1';

/// [sessionBuilder] signed in as [organizerUserId], as `organizer.create`
/// requires (X6).
TestSessionBuilder signedIn(TestSessionBuilder sessionBuilder) =>
    sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        organizerUserId,
        {},
      ),
    );
