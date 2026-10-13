/// Sends a signed-out organizer to sign in, remembering [uri] as where
/// they were going (X6).
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
