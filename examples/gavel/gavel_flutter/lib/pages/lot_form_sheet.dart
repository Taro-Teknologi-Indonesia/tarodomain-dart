import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gavel_client/gavel_client.dart';

import '../core/api.dart';
import '../core/failures.dart';
import '../core/money.dart';
import '../widgets/lot_visual.dart';

/// Opens the add-lot form for the auction with join [code]: a dialog on
/// desktop, a full page under 600 px. Returns the new lot's card, or null if
/// the organizer cancelled.
Future<LotCard?> showLotForm(
  BuildContext context, {
  required String code,
  required String organizerKey,
}) {
  final form = LotFormSheet(code: code, organizerKey: organizerKey);
  if (MediaQuery.sizeOf(context).width < 600) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => form));
  }
  return showDialog<LotCard>(
    context: context,
    builder: (_) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 820),
        child: form,
      ),
    ),
  );
}

/// The structured version of the seller's `-----# LELANG #-----` post.
class LotFormSheet extends StatefulWidget {
  const LotFormSheet({
    required this.code,
    required this.organizerKey,
    super.key,
  });

  /// The auction's join code.
  final String code;

  /// The organizer's secret for this auction.
  final String organizerKey;

  /// The default kelipatan ladder, in rupiah.
  static const presetSteps = [25000, 50000, 100000, 150000, 200000, 300000];

  static const emojis = ['💎', '💍', '🪨', '🔮', '🟢', '🔵', '🔴', '⚪'];

  static const colors = [
    '#2E7D6B',
    '#8D5524',
    '#1E5AA8',
    '#B23A48',
    '#6B4FA0',
    '#4A4A4A',
  ];

  @override
  State<LotFormSheet> createState() => _LotFormSheetState();
}

class _LotFormSheetState extends State<LotFormSheet> {
  final _name = TextEditingController();
  final _openBid = TextEditingController();
  final _description = TextEditingController();
  final _imageUrl = TextEditingController();
  final _customStep = TextEditingController();

  final _selectedSteps = {...LotFormSheet.presetSteps};
  int? _extraStep;
  var _editingCustomStep = false;
  var _emoji = LotFormSheet.emojis.first;
  var _color = LotFormSheet.colors.first;
  var _submitting = false;

  /// The image URL the preview shows: [_imageUrl] once typing pauses, so
  /// the browser doesn't fetch every half-typed URL.
  var _previewUrl = '';
  Timer? _previewDelay;

  /// Inline errors by server field name, from the last submit.
  var _errors = <String, String>{};

  @override
  void initState() {
    super.initState();
    _imageUrl.addListener(() {
      _previewDelay?.cancel();
      _previewDelay = Timer(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _previewUrl = _imageUrl.text.trim());
      });
    });
  }

  @override
  void dispose() {
    _previewDelay?.cancel();
    for (final c in [_name, _openBid, _description, _imageUrl, _customStep]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _openBidValue =>
      int.tryParse(_openBid.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  List<int> get _steps => [
    ...LotFormSheet.presetSteps.where(_selectedSteps.contains),
    if (_extraStep case final step? when _selectedSteps.contains(step)) step,
  ];

  void _addCustomStep() {
    _clearError('increments');
    final thousands = int.tryParse(_customStep.text);
    setState(() {
      _editingCustomStep = false;
      if (thousands == null || thousands <= 0) return;
      final step = thousands * 1000;
      if (_extraStep case final old?
          when !LotFormSheet.presetSteps.contains(old)) {
        _selectedSteps.remove(old);
      }
      _extraStep = LotFormSheet.presetSteps.contains(step) ? null : step;
      _selectedSteps.add(step);
    });
  }

  /// Drops [field]'s server error once the organizer changes the field.
  void _clearError(String field) {
    if (!_errors.containsKey(field)) return;
    setState(() => _errors = {..._errors}..remove(field));
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() {
      _submitting = true;
      _errors = {};
    });
    try {
      final card = await client.lot.add(
        widget.code,
        widget.organizerKey,
        NewLot(
          name: _name.text,
          openBid: _openBidValue,
          increments: _steps,
          description: _description.text,
          imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text,
          tileEmoji: _emoji,
          tileColor: _color,
        ),
      );
      navigator.pop(card);
    } on Object catch (e) {
      if (!mounted) return;
      final failure = GavelFailure.from(e);
      String? snack;
      switch (failure) {
        case Invalid(:final message, :final context):
          final field = context['field'] as String?;
          if (field == null || field == 'lots') {
            snack = message;
          } else {
            setState(() => _errors = {field: message});
          }
        case NotOrganizer():
          snack =
              'Only the organizer can add lots — open the dashboard '
              'from the browser that created this auction.';
        case LotClosed():
          snack = 'The auction has closed; no more lots.';
        case AuctionNotFound():
          snack = 'This auction no longer exists.';
        default:
          snack = 'Could not add the lot. Check your connection and retry.';
      }
      if (snack != null) messenger.showSnackBar(SnackBar(content: Text(snack)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add lot'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancel',
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            onChanged: (_) => _clearError('name'),
            autofocus: true,
            maxLength: 80,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Natural Pirus Hubei',
              errorText: _errors['name'],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _openBid,
            onChanged: (_) => _clearError('openBid'),
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandsFormatter()],
            decoration: InputDecoration(
              labelText: 'Open bid',
              prefixText: 'Rp ',
              hintText: '150.000',
              helperText: 'In rupiah',
              errorText: _errors['openBid'],
            ),
          ),
          const SizedBox(height: 24),
          Text('Kelipatan', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final step in [...LotFormSheet.presetSteps, ?_extraStep])
                FilterChip(
                  label: Text(formatStep(step)),
                  selected: _selectedSteps.contains(step),
                  onSelected: (on) {
                    _clearError('increments');
                    setState(
                      () => on
                          ? _selectedSteps.add(step)
                          : _selectedSteps.remove(step),
                    );
                  },
                ),
              if (_editingCustomStep)
                SizedBox(
                  width: 140,
                  child: TextField(
                    controller: _customStep,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      isDense: true,
                      prefixText: '+',
                      suffixText: 'k',
                    ),
                    onSubmitted: (_) => _addCustomStep(),
                    onTapOutside: (_) => _addCustomStep(),
                  ),
                )
              else
                ActionChip(
                  avatar: const Icon(Icons.add, size: 18),
                  label: const Text('custom step'),
                  onPressed: () => setState(() {
                    _customStep.clear();
                    _editingCustomStep = true;
                  }),
                ),
            ],
          ),
          if (_errors['increments'] ?? (_steps.isEmpty ? '' : null)
              case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error.isEmpty ? 'Choose at least one step' : error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 24),
          TextField(
            controller: _description,
            onChanged: (_) => _clearError('description'),
            minLines: 4,
            maxLines: 10,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Berat: …\nUkuran: …\nAsal: …\nIkatan: …\nKondisi: …',
              alignLabelWithHint: true,
              errorText: _errors['description'],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _imageUrl,
                  onChanged: (_) => _clearError('imageUrl'),
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: 'Image URL (optional)',
                    hintText: 'https://…',
                    helperText: 'If it fails to load, the tile shows instead',
                    errorText: _errors['imageUrl'],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox.square(
                  dimension: 64,
                  child: LotVisual(
                    imageUrl: _previewUrl,
                    emoji: _emoji,
                    color: _color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Tile', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              for (final emoji in LotFormSheet.emojis)
                ChoiceChip(
                  label: Text(emoji, style: const TextStyle(fontSize: 20)),
                  selected: emoji == _emoji,
                  showCheckmark: false,
                  onSelected: (_) {
                    _clearError('tileEmoji');
                    setState(() => _emoji = emoji);
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final color in LotFormSheet.colors)
                _Swatch(
                  color: color,
                  selected: color == _color,
                  onTap: () {
                    _clearError('tileColor');
                    setState(() => _color = color);
                  },
                ),
            ],
          ),
          if (_errors['tileEmoji'] ?? _errors['tileColor'] case final error?)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.gavel),
            label: const Text('Add lot'),
          ),
        ],
      ),
    );
  }
}

/// One tile color to pick.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: 'Tile color $color',
    child: InkResponse(
      onTap: onTap,
      radius: 22,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: TileVisual.parse(color),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    ),
  );
}

/// Keeps only digits and shows them with Indonesian thousands separators:
/// typing 150000 shows `150.000`.
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    // A trillion rupiah is plenty, and stays a safe integer on the web.
    if (digits.length > 13) return oldValue;
    final text = formatThousands(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
