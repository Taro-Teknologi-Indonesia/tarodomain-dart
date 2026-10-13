import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/api.dart';
import 'router.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  // Restores the organizer's session before the first redirect, so
  // reloading /new doesn't send a signed-in organizer to /sign-in.
  await client.auth.initialize();
  runApp(const GavelApp());
}

/// Gavel: a live silent auction that closes itself.
class GavelApp extends StatelessWidget {
  const GavelApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Gavel',
    theme: gavelTheme(),
    debugShowCheckedModeBanner: false,
    routerConfig: router,
  );
}
