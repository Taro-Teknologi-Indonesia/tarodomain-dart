import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/api.dart';
import '../core/clock.dart';
import '../core/failures.dart';
import '../core/organizer_keys.dart';

/// The organizer's first step: a title and one close time for every lot
/// (UC-01).
class CreateAuctionPage extends StatefulWidget {
  const CreateAuctionPage({super.key});

  @override
  State<CreateAuctionPage> createState() => _CreateAuctionPageState();
}

class _CreateAuctionPageState extends State<CreateAuctionPage> {
  final _title = TextEditingController();
  late DateTime _closeAt = _defaultCloseAt();
  late final Timer _ticker;
  var _submitting = false;

  /// Inline errors by server field name, from the last submit.
  var _errors = <String, String>{};

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
      _closeAt = DateTime(
        _closeAt.year,
        _closeAt.month,
        _closeAt.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _submitting = true;
      _errors = {};
    });
    try {
      final created = await client.auction.create(
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
    final remaining = _closeAt.difference(DateTime.now());
    final closeText =
        'Closes at ${DateFormat.Hm().format(_closeAt)} '
        '${_closeAt.timeZoneName}'
        '${remaining.isNegative ? ' (in the past)' : ' (in ${formatRemaining(remaining)})'}';
    return Scaffold(
      appBar: AppBar(title: const Text('New auction')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _title,
                  autofocus: true,
                  maxLength: 80,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Lelang batu malam Jumat',
                    errorText: _errors['title'],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Close time', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(DateFormat.yMMMEd().format(_closeAt)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.schedule),
                        label: Text(DateFormat.Hm().format(_closeAt)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(closeText),
                if (_errors['closeAt'] case final error?)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      error,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create auction'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
