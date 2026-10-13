import 'package:flutter/material.dart';

/// An auction's live board (UC-04), or its big-screen mode (UC-11).
class BoardPage extends StatelessWidget {
  const BoardPage({required this.code, this.bigScreen = false, super.key});

  /// The auction's join code.
  final String code;

  /// Whether to show the read-only projector layout.
  final bool bigScreen;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Auction $code')),
    body: Center(
      child: Text(code, style: Theme.of(context).textTheme.displayMedium),
    ),
  );
}
