import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'router.dart';

void main() {
  usePathUrlStrategy();
  runApp(const GavelApp());
}

/// Gavel: a live silent auction that closes itself.
class GavelApp extends StatelessWidget {
  const GavelApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Gavel',
    theme: ThemeData(colorSchemeSeed: const Color(0xFF8D5524)),
    routerConfig: router,
  );
}
