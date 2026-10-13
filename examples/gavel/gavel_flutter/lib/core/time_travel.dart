import 'package:gavel_client/gavel_client.dart';

/// A past moment to view a lot at (UC-10), with what to call it.
class Moment {
  const Moment(this.at, this.label);

  /// The moment, in UTC.
  final DateTime at;

  /// What the picker shows: "Before first bid", "22:02", "#3 Budi".
  final String label;

  @override
  bool operator ==(Object other) =>
      other is Moment && other.at == at && other.label == label;

  @override
  int get hashCode => Object.hash(at, label);

  @override
  String toString() => 'Moment($at, $label)';
}

const _ms = Duration(milliseconds: 1);

/// The quick picks for [ledger]: "Before first bid", then the start of
/// each minute after one with activity (22:01, 22:02…), then "Just before
/// close" once the lot closed at [closedAt]. Minutes from [end] on are
/// left out: that's the live view, or the close.
///
/// [clock] formats a minute for its label.
List<Moment> presetsFor(
  List<LedgerEntry> ledger, {
  required DateTime end,
  required DateTime? closedAt,
  required String Function(DateTime) clock,
}) {
  if (ledger.isEmpty) return const [];
  final times = _activity(ledger);
  final minutes = <DateTime>{
    for (final t in times)
      if (_nextMinute(t) case final m when m.isBefore(end)) m,
  }.toList()..sort();
  return [
    Moment(times.first.subtract(_ms), 'Before first bid'),
    for (final m in minutes) Moment(m, clock(m)),
    if (closedAt != null) Moment(closedAt.subtract(_ms), 'Just before close'),
  ];
}

/// The slider's stops for [ledger]: just before the first bid, then each
/// bid and each retraction, oldest first. The slider snaps to these, so
/// every step changes something on the ledger.
List<Moment> stopsFor(List<LedgerEntry> ledger) {
  if (ledger.isEmpty) return const [];
  final events = <Moment>[
    for (final e in ledger) ...[
      Moment(e.placedAt, '#${e.sequence} ${e.bidderName}'),
      if (e.retractedAt case final at?) Moment(at, '#${e.sequence} retracted'),
    ],
  ]..sort((a, b) => a.at.compareTo(b.at));
  return [Moment(events.first.at.subtract(_ms), 'Before first bid'), ...events];
}

List<DateTime> _activity(List<LedgerEntry> ledger) => [
  for (final e in ledger) ...[e.placedAt, ?e.retractedAt],
]..sort();

/// The first whole minute strictly after [t], so the minute holding [t] is
/// all in.
DateTime _nextMinute(DateTime t) {
  final utc = t.toUtc();
  return DateTime.utc(utc.year, utc.month, utc.day, utc.hour, utc.minute + 1);
}

/// How a ledger row reads as of a past moment.
extension AsOfRules on LedgerEntry {
  /// Whether the bid came after [at], so it's dimmed.
  bool placedAfter(DateTime at) => placedAt.isAfter(at);

  /// Whether the bid had been taken back by [at]: one retracted later
  /// still stands then.
  bool retractedBy(DateTime at) =>
      retracted && !(retractedAt?.isAfter(at) ?? false);
}
