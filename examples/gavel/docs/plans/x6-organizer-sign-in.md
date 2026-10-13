# X6 — Organizer sign-in with Serverpod auth (cross-cutting, Should)

Depends on: UC-01 (done). Changes how UC-01 starts; bidders are untouched. About 2 h. Judging: **Serverpod stack (25%)**, since it uses the auth module, JWT and `requireLogin`.

## Goal

Tapping **Create an auction** asks the organizer to sign in with Serverpod's auth module (email plus a verification code). Once they're signed in, the app opens the create form they asked for, with no extra tap. The server refuses `create` without a signed-in user, so the gate isn't only in the UI. Every new auction records which account created it.

## Scope

- **Organizers only.** Bidders keep joining with a display name and a participant key, with no account (UC-03). An account doesn't fix non-payment (the reason Facebook login was rejected), and an account wall in front of a join link would cost the funnel.
- **Only creating is gated.** The organizer key still guards AddLot, MarkUnpaid and the winner codes. Auctions created before X6, the demo auction (opened by the server job, with no user) and an organizer dashboard in the browser that created it all work as before.
- **Email is the only provider.** Serverpod Cloud sends the verification codes itself (`ServerpodCloudEmailIdpConfig`), so there's no SMTP server or third-party console to set up. In the `development` and `test` run modes, the codes go to the server log instead. Google or another provider can be added later as one more `identityProviderBuilders` entry, and `SignInWidget` shows it with no app change.
- **Not in this plan:** "My auctions" across browsers, organizer rights by account instead of by key, and cookie-based web auth (see Later).

## Packages

Pin each one to the Serverpod version, like the other Serverpod packages:

| Package | Add |
|---|---|
| `gavel_server` | `serverpod_auth_idp_server: 4.0.4` |
| `gavel_client` | `serverpod_auth_idp_client: 4.0.4` |
| `gavel_flutter` | `serverpod_auth_idp_flutter: 4.0.4` |

`serverpod_auth_idp_client` pins `serverpod_client` exactly (4.0.1 pins 4.0.1), so its version must match the client's `serverpod_client: 4.0.4`.

**Copy the setup from a scratch project.** Run `~/.pub-cache/bin/serverpod create gavel_auth_scratch` in a temp folder: the 4.x template ships email and JWT auth already wired (`server.dart`, `lib/src/auth/`, passwords, the Flutter `main.dart` and its sign-in screen). Copy the exact imports from it rather than guessing; the docs don't name the import of `ServerpodCloudEmailIdpConfig`.

## Server

### Auth services (`lib/server.dart`)

Before `pod.start()`:

```dart
pod.initializeAuthServices(
  tokenManagerBuilders: [JwtConfigFromPasswords()],
  identityProviderBuilders: [
    ServerpodCloudEmailIdpConfig(appDisplayName: 'Gavel'),
  ],
);
```

### Auth endpoints (`lib/src/auth/`)

```dart
// email_idp_endpoint.dart
import 'package:serverpod_auth_idp_server/providers/email.dart';

/// Email sign-up, sign-in and password reset for organizers (X6).
class EmailIdpEndpoint extends EmailIdpBaseEndpoint {}
```

```dart
// refresh_jwt_tokens_endpoint.dart
import 'package:serverpod_auth_idp_server/core.dart' as core;

/// Renews the app's access token, so an organizer stays signed in.
class RefreshJwtTokensEndpoint extends core.RefreshJwtTokensEndpoint {}
```

### `create` moves to `OrganizerEndpoint`

Serverpod's `requireLogin` applies to a whole endpoint, not a single method, and `AuctionEndpoint` must stay public for `board`, `join`, `checkParticipant` and `currentDemo`. So `create` moves to a new endpoint:

```dart
/// What only a signed-in organizer can do (X6).
class OrganizerEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Creates an auction called [title] that closes at [closeAt], truncated
  /// to the second, schedules its close, and records the signed-in user
  /// as its creator.
  ///
  /// The returned organizer key is sent only this once.
  Future<CreatedAuction> create(
    Session session,
    String title,
    DateTime closeAt,
  ) => createAuction(
    session,
    title: title,
    closeAt: closeAt,
    organizerUserId: session.authenticated!.userIdentifier,
  );
}
```

- Delete `AuctionEndpoint.create`. If it stayed, any client could skip the sign-in.
- Serverpod answers a call without a valid token with 401 before the method runs. When an access token expires, the client renews it through `RefreshJwtTokensEndpoint`.

### Domain: who created the auction

- `CreateAuction` and `AuctionCreated` get `String? organizerUserId`, the auth user's `userIdentifier`. `Auction` keeps it in its state.
- `AuctionCreated.fromData` reads `data['organizerUserId'] as String?`. Events from before X6, and the demo's, have none.
- It's nullable on purpose: the demo job creates auctions with no user (X2). The endpoint guarantees a user for every auction an organizer creates; the domain doesn't need to.
- `createAuction(…, String? organizerUserId)` in `infra/auction_creation.dart` passes it through. The demo's call doesn't change.
- Only the event and the aggregate hold it. `AuctionView` gets no column until "My auctions" needs one.

### Database and passwords

- Run `serverpod generate`, then `serverpod create-migration` (CLI at `~/.pub-cache/bin/serverpod`). The migration adds the auth module's tables (users, email accounts, refresh tokens). `tool/deploy.sh` applies it, like the earlier ones.
- In `config/passwords.yaml`, add `jwtHmacSha512PrivateKey`, `jwtRefreshTokenHashPepper` and `emailSecretHashPepper` with throwaway local values under **both** `development` and `test`, like the database password there. Without them under `test`, `withServerpod` fails at start-up.
- Production, once before the deploy: `serverpod cloud password set` for the same three keys, with fresh random values (`openssl rand -base64 64` for the JWT key, `openssl rand -base64 32` for the peppers). Serverpod Cloud sets `scloudAuthEmailKey`, the key for sending email, itself on deploy.

## Flutter

### Client (`core/api.dart`)

```dart
final client = Client(apiUrl)
  ..connectivityMonitor = FlutterConnectivityMonitor()
  ..authSessionManager = FlutterAuthSessionManager();
```

### Start-up (`main.dart`)

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  // Restores the organizer's session before the first redirect, so
  // reloading /new doesn't send a signed-in organizer to /sign-in.
  await client.auth.initialize();
  runApp(const GavelApp());
}
```

`initialize` restores the stored session and checks it with the server, with a 2 s timeout by default. A bidder has no stored session; check on the deployed app that opening a join link isn't any slower.

### Routes (`router.dart`)

```dart
final router = GoRouter(
  // Runs the redirects again on sign-in and sign-out.
  refreshListenable: client.auth.authInfoListenable,
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomePage()),
    GoRoute(
      path: '/new',
      redirect: (_, state) =>
          requireSignIn(client.auth.isAuthenticated, state.uri),
      builder: (_, _) => const CreateAuctionPage(),
    ),
    GoRoute(
      path: '/sign-in',
      redirect: (_, state) =>
          leaveSignIn(client.auth.isAuthenticated, state.uri),
      builder: (_, _) => const SignInPage(),
    ),
    // … /demo and the /a/:code shell, unchanged
  ],
);
```

The redirect rules live as pure functions in `core/auth_redirects.dart`, so they can be unit tested without a client:

```dart
/// Sends a signed-out organizer to sign in, remembering [uri] as where
/// they were going.
String? requireSignIn(bool signedIn, Uri uri) => signedIn
    ? null
    : Uri(path: '/sign-in', queryParameters: {'from': '$uri'}).toString();

/// Sends a signed-in organizer on from /sign-in to where they were going.
String? leaveSignIn(bool signedIn, Uri uri) =>
    signedIn ? returnPath(uri.queryParameters['from']) : null;

/// [from] if it's a path inside the app, else /new. Never another site:
/// `//evil.example` and `https://…` are refused.
String returnPath(String? from) =>
    from != null &&
        from.startsWith('/') &&
        !from.startsWith('//') &&
        !from.contains(r'\')
    ? from
    : '/new';
```

The flow:

1. On the home page, **Create an auction** calls `context.go('/new')`, as it does now.
2. Signed out, `/new` redirects to `/sign-in?from=%2Fnew`.
3. `SignInPage` shows `SignInWidget`, where the organizer registers (email, code, password) or signs in.
4. Signing in changes `authInfoListenable`, so go_router runs the `/sign-in` redirect again and opens `/new`. The page doesn't navigate in `onAuthenticated`, as Serverpod's docs advise; the router does it.
5. Signed in, `/new` opens directly with no sign-in screen, after a reload too.

### `pages/sign_in_page.dart`

- A `Scaffold` with the title "Sign in to create an auction" and a back button to `/`, in the same 480 px column as the create form.
- One line above the widget: "Only organizers sign in. Bidders never need an account."
- `SignInWidget(client: client, onError: …)`, where `onError` shows a snackbar. It has no `onAuthenticated` navigation.

### Create page, home page and failures

- `CreateAuctionPage`'s default `create` becomes `client.organizer.create`. The page's `create` test seam keeps its widget tests free of auth.
- `GavelFailure.from` maps `ServerpodClientUnauthorized` to a new `SignedOut` failure. On it, `_submit` calls `client.auth.signOutDevice()`, and the router redirects to `/sign-in?from=%2Fnew`. That happens only if the session is revoked while the form is open. The typed title is lost, which is acceptable for this rare case.
- In the home page's **New auction** card, a `ListenableBuilder` on `client.auth.authInfoListenable` shows a **Sign out** text button while signed in. Signing out from `/` triggers no redirect.
- The organizer dashboard doesn't change.

When the signed-in identity changes, the session manager closes open streaming connections. Sign-in and sign-out happen on `/sign-in` and `/`, where no live board is open, and the controller in `core/live.dart` reconnects on `onDone` anyway.

## Tests

Server integration (`test/integration/organizer_test.dart`):

- `organizer.create` with no signed-in user throws `ServerpodUnauthenticatedException` and leaves no `AuctionView` row.
- With `sessionBuilder.copyWith(authentication: AuthenticationOverride.authenticationInfo('organizer-1', {}))`, it creates the auction, and the loaded `Auction` has `organizerUserId == 'organizer-1'`.
- The existing callers of `endpoints.auction.create` (the auction, bid, buy_now, demo, lot_detail and participant tests) switch to `endpoints.organizer.create` with a signed-in builder from one shared helper, `signedIn(sessionBuilder)` in `test/integration/organizer_session.dart`.

Server domain:

- `AuctionCreated` round-trips `organizerUserId` through `toData`/`fromData`, and data without the key reads back as null.

Flutter:

- `test/core/auth_redirects_test.dart`:
  - Signed out on `/new` → `/sign-in?from=%2Fnew`. Signed in → no redirect.
  - Signed in on `/sign-in?from=%2Fnew` → `/new`. A `from` of `//evil.example`, `https://evil.example` or none → `/new`.
  - Signed out on `/sign-in` → no redirect.
- `failures_test`: `ServerpodClientUnauthorized` maps to `SignedOut`.

Manual, before deploying:

- Local: Create an auction → sign-in screen → register, reading the code from the server log → the create form opens → create → the dashboard opens.
- Reload `/new` while signed in: the form opens, not the sign-in screen.
- Deployed: register with a real address and check the code arrives by email.

## Docs

- **Judges' README (X4):** the Serverpod mapping gains "auth module: email sign-in, JWT, `requireLogin` on `OrganizerEndpoint`". The 2-minute try-it says that creating an auction asks for an email sign-up, and that `/demo` needs none.
- **UC-01 plan:** mark the endpoint section as moved to `OrganizerEndpoint`, and the sign-in step as built.

## Acceptance

- [ ] Signed out, **Create an auction** opens the sign-in screen. After signing in or registering, the create form opens with no extra tap.
- [ ] Signed in, **Create an auction** opens the form directly, also after a reload.
- [x] Calling `organizer.create` without a token gets 401, and `auction.create` no longer exists.
- [x] Every new organizer auction's `AuctionCreated` carries the creator's `organizerUserId`; the demo's doesn't.
- [ ] Bidders join and bid with no account, as before. The demo and existing auctions work unchanged.
- [ ] On the deployed app, the verification code arrives by email.

## Verify first (about 15 min, before writing code)

1. All three `serverpod_auth_idp_*` packages resolve at 4.0.4 next to `serverpod: 4.0.4`.
2. `tool/build_web.sh` still builds after adding `serverpod_auth_idp_flutter`, which brings the other providers' platform plugins.
3. The web app at `<project>.serverpod.space` can call `<project>.api.serverpod.space` with an `Authorization` header (the CORS preflight allows it). Cookie auth would need `authCookie` and `allowedOrigins` across the two hosts, so it stays out of this plan.
4. The 4.0.4 signature of `AuthenticationOverride.authenticationInfo` in `serverpod_test`: a `String` user identifier and a set of scopes.

If step 1 or 3 fails and can't be fixed quickly, drop X6 and keep the organizer key alone. Nothing else depends on it.

## Later (not this plan)

- **My auctions:** an `organizerUserId` column on `AuctionView`, an `organizer.myAuctions()` call and a list on the home page.
- **Organizer rights by account:** AddLot, MarkUnpaid and the winner codes accept the signed-in creator as well as the key. The dashboard then works in any browser the organizer signs into, which ends the "Read-only — open from the browser that created this auction" case.
- **Google sign-in** as a second provider, for one-tap sign-in.
- **Cookie-based web auth** (`httpOnly` tokens) once the app and the API share a cookie domain.

Estimate: 2 h (0.25 h verify, 0.75 h server and tests, 0.75 h Flutter, 0.25 h secrets and deploy).
