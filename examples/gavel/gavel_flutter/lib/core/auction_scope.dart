import 'package:flutter/widgets.dart';

import 'api.dart';
import 'auction_controller.dart';

/// Holds one [AuctionController] for every page of the auction with join
/// [code]: the board, a lot's detail and the organizer dashboard share its
/// one live subscription.
class AuctionScope extends StatefulWidget {
  const AuctionScope({required this.code, required this.child, super.key});

  /// The auction's join code.
  final String code;

  final Widget child;

  /// The controller of the nearest scope, rebuilding [context] on every
  /// change.
  static AuctionController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AuctionNotifier>()!.notifier!;

  /// The controller of the nearest scope, without rebuilding [context] on
  /// changes: for listeners and callbacks.
  static AuctionController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_AuctionNotifier>()!.notifier!;

  @override
  State<AuctionScope> createState() => _AuctionScopeState();
}

class _AuctionScopeState extends State<AuctionScope> {
  late final _auction = AuctionController(client, widget.code)..start();

  @override
  void dispose() {
    _auction.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _AuctionNotifier(notifier: _auction, child: widget.child);
}

class _AuctionNotifier extends InheritedNotifier<AuctionController> {
  const _AuctionNotifier({required super.notifier, required super.child});
}
