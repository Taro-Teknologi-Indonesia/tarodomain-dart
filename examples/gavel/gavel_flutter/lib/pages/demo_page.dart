import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/api.dart';

/// `/demo`: finds the open public demo auction and goes to its board (X2).
class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    setState(() => _failed = false);
    try {
      final code = await client.auction.currentDemo();
      if (mounted) context.go('/a/$code');
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: _failed
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('The demo auction could not be opened.'),
                const SizedBox(height: 16),
                FilledButton(onPressed: _open, child: const Text('Try again')),
              ],
            )
          : const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Finding the live demo auction…'),
              ],
            ),
    ),
  );
}
