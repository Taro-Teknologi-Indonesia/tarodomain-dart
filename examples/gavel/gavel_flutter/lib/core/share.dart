import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Copies the URL of the lot [lotId] in the auction with join [code], the
/// receipt a winner pastes back (UC-09), and says so.
Future<void> copyLotLink(
  BuildContext context,
  String code,
  String lotId,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final url = Uri.base.resolve('/a/$code/lot/$lotId');
  await Clipboard.setData(ClipboardData(text: url.toString()));
  messenger.showSnackBar(const SnackBar(content: Text('Link copied')));
}
