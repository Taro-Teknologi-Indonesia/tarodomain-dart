import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_client/rules.dart';

import '../core/api.dart';
import '../core/failures.dart';
import '../core/identity.dart';
import '../core/input_formatters.dart';

/// Asks for a display name and joins the auction with join [code].
///
/// Pops with the new [Identity], or null if dismissed. The board stays
/// visible behind it.
class JoinSheet extends StatefulWidget {
  const JoinSheet({
    required this.code,
    this.message,
    @visibleForTesting this.join,
    super.key,
  });

  final String code;

  /// Sends `auction.join`; the app's client unless a test passes one.
  final Future<JoinResult> Function(String code, String displayName)? join;

  /// Why the sheet is shown, under its title, such as a lost identity.
  final String? message;

  /// Shows the sheet above the keyboard and returns the identity joined.
  static Future<Identity?> show(
    BuildContext context,
    String code, {
    String? message,
  }) => showModalBottomSheet<Identity>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => JoinSheet(code: code, message: message),
  );

  @override
  State<JoinSheet> createState() => _JoinSheetState();
}

class _JoinSheetState extends State<JoinSheet> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// What to show for a display name refused for [reason], whether the
  /// app or the server refused it.
  static String _nameError(String? reason) => reason == 'EMPTY'
      ? 'Enter the name others will see'
      : 'Use 1 to ${ParticipantRules.maxNameLength} characters';

  Future<void> _join() async {
    if (_busy) return;
    final name = _name.text.trim();
    if (ParticipantRules.displayName(name) case final error?) {
      setState(() => _error = _nameError(error.reason));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await (widget.join ?? client.auction.join)(
        widget.code,
        name,
      );
      final identity = Identity.joined(result);
      await Identities.save(widget.code, identity);
      if (mounted) Navigator.of(context).pop(identity);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = switch (GavelFailure.from(e)) {
          Invalid(:final context) => _nameError(context['reason'] as String?),
          AuctionNotFound() => 'This auction no longer exists',
          _ => 'Could not join. Check your connection and try again.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      // Keeps the field above the phone's keyboard.
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Join to bid', style: theme.textTheme.titleLarge),
          if (widget.message case final message?) ...[
            const SizedBox(height: 4),
            Text(message),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            autofocus: true,
            // Counts graphemes, the server runes: the rule above catches
            // a name of emoji that fits here.
            maxLength: ParticipantRules.maxNameLength,
            inputFormatters: [NoControlCharactersFormatter()],
            enabled: !_busy,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Your name as shown to others',
              errorText: _error,
            ),
            onSubmitted: (_) => _join(),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _join,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: _busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Join'),
          ),
        ],
      ),
    );
  }
}
