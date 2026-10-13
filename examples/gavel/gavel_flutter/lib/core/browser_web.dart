import 'package:web/web.dart' as web;

/// Shows the page full screen, as the projector shows it (UC-11).
void requestFullscreen() => web.document.documentElement?.requestFullscreen();

/// Opens [url] in a new tab.
void openInNewTab(String url) => web.window.open(url, '_blank');
