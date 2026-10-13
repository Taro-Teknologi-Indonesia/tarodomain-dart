import 'package:flutter/material.dart';

/// One lot's detail and bid ledger (UC-05).
class LotPage extends StatelessWidget {
  const LotPage({required this.code, required this.lotId, super.key});

  /// The auction's join code.
  final String code;

  /// The lot.
  final String lotId;

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text('Lot $lotId')));
}
