import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gavel_client/gavel_client.dart';
import 'package:gavel_client/rules.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/clock.dart';
import '../core/failures.dart';
import '../core/organizer_keys.dart';
import '../theme.dart';
import '../widgets/brand.dart';

/// The organizer's first step: a title and one close time for every lot
/// (UC-01).
class CreateAuctionPage extends StatefulWidget {
  const CreateAuctionPage({@visibleForTesting this.create, super.key});

  /// Sends `organizer.create`; the app's client unless a test passes one,
  /// which keeps the widget tests free of sign-in (X6).
  final Future<CreatedAuction> Function(String title, DateTime closeAt)? create;

  @override
  State<CreateAuctionPage> createState() => _CreateAuctionPageState();
}

class _CreateAuctionPageState extends State<CreateAuctionPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  late DateTime _closeAt = _defaultCloseAt();
  late final Timer _ticker;
  var _submitting = false;

  /// Inline errors by server field name, from the last submit.
  var _errors = <String, String>{};

  /// Off until the first submit, so errors don't show while the organizer
  /// is still typing for the first time.
  var _autovalidate = AutovalidateMode.disabled;

  /// An hour from now, on the next whole 5 minutes.
  static DateTime _defaultCloseAt() {
    final t = DateTime.now().add(const Duration(hours: 1));
    final rounded = DateTime(t.year, t.month, t.day, t.hour, t.minute);
    return rounded.add(Duration(minutes: (5 - rounded.minute % 5) % 5));
  }

  @override
  void initState() {
    super.initState();
    // Keeps "in 2 h 14 m" current.
    _ticker = Timer.periodic(
      const Duration(seconds: 15),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _closeAt,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null) return;
    setState(() {
      _errors = {..._errors}..remove('closeAt');
      _closeAt = DateTime(
        date.year,
        date.month,
        date.day,
        _closeAt.hour,
        _closeAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_closeAt),
      initialEntryMode: TimePickerEntryMode.input,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null) return;
    setState(() {
      _errors = {..._errors}..remove('closeAt');
      _closeAt = DateTime(
        _closeAt.year,
        _closeAt.month,
        _closeAt.day,
        time.hour,
        time.minute,
      );
    });
  }

  /// Drops [field]'s server error once the organizer changes the field.
  void _clearError(String field) {
    if (!_errors.containsKey(field)) return;
    setState(() => _errors = {..._errors}..remove(field));
  }

  Future<void> _submit() async {
    // Checked now, not when picked: a form left open goes stale. The
    // server checks again, against its own clock.
    final closeAtError = AuctionRules.closeAt(_closeAt, now: DateTime.now());
    final titleValid = _form.currentState!.validate();
    setState(() {
      _autovalidate = AutovalidateMode.onUserInteraction;
      _errors = {'closeAt': ?closeAtError?.message};
    });
    if (!titleValid || closeAtError != null) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _submitting = true);
    try {
      final created = await (widget.create ?? client.organizer.create)(
        _title.text,
        _closeAt.toUtc(),
      );
      await OrganizerKeys.save(created.code, created.organizerKey);
      router.go('/a/${created.code}/organizer');
    } on Object catch (e) {
      if (!mounted) return;
      switch (GavelFailure.from(e)) {
        case Invalid(:final message, :final context)
            when context['field'] is String:
          setState(() => _errors = {context['field']! as String: message});
        case SignedOut():
          // Only if the session was revoked while the form was open. The
          // router then sends the organizer to sign in again.
          await client.auth.signOutDevice();
        default:
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Could not create the auction. Check your connection and '
                'retry.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final remaining = _closeAt.difference(now);
    final tooSoon = AuctionRules.closeAt(_closeAt, now: now) != null;
    final closeText =
        'Closes at ${DateFormat.Hm().format(_closeAt)} '
        '${_closeAt.timeZoneName}'
        '${remaining.isNegative ? ' (in the past)' : ' (in ${formatRemaining(remaining)})'}'
        '${tooSoon ? ' — at least ${AuctionRules.minimumLeadTime.inMinutes} minutes from now' : ''}';
    final closeColor = tooSoon ? theme.colorScheme.error : Brand.lead;
    return Scaffold(
      appBar: AppBar(title: const Text('New auction')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _form,
              autovalidateMode: _autovalidate,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Eyebrow('Step 1 of 2', color: Brand.goldDeep),
                  const SizedBox(height: 8),
                  Text(
                    'Set up your auction',
                    style: Brand.display.copyWith(
                      fontSize: 34,
                      color: Brand.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Name it and pick one close time. Every lot closes '
                    'together, on the second, so nobody argues about who '
                    'was first.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Brand.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _title,
                            autofocus: true,
                            maxLength: AuctionRules.maxTitleLength,
                            validator: (title) =>
                                AuctionRules.title(title ?? '')?.message,
                            onChanged: (_) => _clearError('title'),
                            decoration: InputDecoration(
                              labelText: 'Title',
                              hintText: 'Lelang batu malam Jumat',
                              prefixIcon: const Icon(Icons.edit_outlined),
                              errorText: _errors['title'],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Close time', style: theme.textTheme.titleSmall),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _PickerTile(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Date',
                                  value: DateFormat.yMMMEd().format(_closeAt),
                                  onTap: _pickDate,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _PickerTile(
                                  icon: Icons.schedule_rounded,
                                  label: 'Time',
                                  value: DateFormat.Hm().format(_closeAt),
                                  onTap: _pickTime,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: closeColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  tooSoon
                                      ? Icons.error_outline_rounded
                                      : Icons.timer_outlined,
                                  size: 18,
                                  color: closeColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    closeText,
                                    style: TextStyle(
                                      color: closeColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_errors['closeAt'] case final error?)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                error,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: Brand.goldButton.copyWith(
                      minimumSize: const WidgetStatePropertyAll(
                        Size.fromHeight(56),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Brand.ink,
                            ),
                          )
                        : const Text('Create auction'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Next: add your lots, then share one link with your '
                    'group.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Brand.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled value that opens a picker, such as the close date.
class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Brand.ivory,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Brand.line),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Brand.goldDeep),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(label),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      fontFeatures: Brand.tabular,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
