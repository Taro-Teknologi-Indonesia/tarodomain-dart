/// What the page asks of the browser it runs in. Off the web (in tests)
/// these do nothing.
library;

export 'browser_stub.dart' if (dart.library.js_interop) 'browser_web.dart';
