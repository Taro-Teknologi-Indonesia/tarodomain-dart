// Proves Gavel's concurrency claims against a running server with real
// parallel requests and no artificial delay anywhere (X3).
//
//   dart run tool/race.dart --host https://<host> --code ABC123 [--lot <id>]
//       [--bidders 20] [--mode bid|close-race] [--window-ms 300]
//
// `bid` (the default): N fresh participants read the lot once and all bid
// the smallest raise on the same version at the same moment. Exactly one
// must win; every other bid must come back OUTBID naming that winner.
//
// `close-race`: N bids spread across ±window around the auction's close.
// Every bid must be accepted, OUTBID or LOT_CLOSED; no ledger row may be
// dated at or after the close; and the lot must close SOLD to its last
// valid bid.
//
// Exits 0 when every check holds, 1 when one fails and 64 on bad usage, so
// it doubles as a smoke test after a deploy. The bidders are real
// participants named race-1…race-N, visible in the ledger.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:gavel_client/gavel_client.dart';
import 'package:tarodomain_serverpod_client/tarodomain_serverpod_client.dart';

/// More bidders than this looks like load-testing someone's server.
const _maxBidders = 50;

Future<void> main(List<String> arguments) async {
  final _Options options;
  try {
    options = _Options.parse(arguments);
  } on FormatException catch (e) {
    stderr
      ..writeln('race: ${e.message}')
      ..writeln(_Options.usage);
    exit(64);
  }

  final clients = <Client>[];
  try {
    final ok = await _run(options, clients);
    exitCode = ok ? 0 : 1;
  } on TaroDomainException catch (e) {
    stderr.writeln('race: ${e.code}: ${e.message}');
    exitCode = 1;
  } on FormatException catch (e) {
    stderr.writeln('race: ${e.message}');
    exitCode = 1;
  } on ServerpodClientException catch (e) {
    stderr.writeln('race: ${options.host} answered: $e');
    exitCode = 1;
  } finally {
    for (final client in clients) {
      client.close();
    }
  }
}

Future<bool> _run(_Options options, List<Client> clients) async {
  Client connect() {
    final client = Client(options.host);
    clients.add(client);
    return client;
  }

  final reader = connect();
  final lotId = options.lotId ?? await _firstOpenLot(reader, options.code);
  final before = await _timedDetail(reader, lotId);
  if (before.detail.lot.status != 'OPEN') {
    stderr.writeln('race: lot $lotId is ${before.detail.lot.status}, not OPEN');
    return false;
  }

  // One client per bidder, so every bid travels on its own connection. The
  // join warms that connection, so the bids race each other, not TLS.
  stdout.writeln('joining ${options.bidders} bidders to ${options.code}…');
  final bidders = await Future.wait([
    for (var i = 1; i <= options.bidders; i++)
      () async {
        final client = connect();
        final joined = await client.auction.join(options.code, 'race-$i');
        return _Bidder(client, joined);
      }(),
  ]);

  return switch (options.mode) {
    _Mode.bid => _bidRace(reader, lotId, bidders),
    _Mode.closeRace => _closeRace(reader, lotId, bidders, options.window),
  };
}

/// N bids on one version at once: exactly one may land.
Future<bool> _bidRace(
  Client reader,
  UuidValue lotId,
  List<_Bidder> bidders,
) async {
  final before = await reader.lot.detail(lotId);
  final lot = before.lot;
  final amount = lot.currentPrice + lot.increments.first;

  final outcomes = await Future.wait([
    for (final bidder in bidders) bidder.bid(lotId, amount, lot.version),
  ]);

  final after = await reader.lot.detail(lotId);
  final added = after.ledger.length - before.ledger.length;
  final accepted = [
    for (final o in outcomes)
      if (o.accepted) o,
  ];
  final outbid = [
    for (final o in outcomes)
      if (o.code == 'OUTBID') o,
  ];
  final other = outcomes.length - accepted.length - outbid.length;

  final winner = accepted.length == 1 ? accepted.single.bidder : null;
  final namedWinner =
      winner != null &&
      outbid.every((o) => o.context['leaderId'] == winner.id.uuid);
  final rowIsWinner =
      winner != null &&
      added == 1 &&
      after.ledger.last.participantId == winner.id &&
      after.ledger.last.amount == amount;

  stdout
    ..writeln()
    ..writeln(
      '${bidders.length} bids at version ${lot.version}, '
      'price ${_rupiah(lot.currentPrice)}',
    )
    ..writeln(
      '  accepted : ${_pad(accepted.length)}'
      '${winner == null ? '' : '(${winner.name} → ${_rupiah(amount)})'}',
    )
    ..writeln(
      '  OUTBID   : ${_pad(outbid.length)}'
      '${outbid.isEmpty
          ? ''
          : namedWinner
          ? '(all named ${winner.name} as leader)'
          : '(NOT all named the winner)'}',
    )
    ..writeln('  other    : $other${_codes(outcomes)}')
    ..writeln('ledger rows added: $added');

  final failures = [
    if (accepted.length != 1) 'accepted ${accepted.length}, expected 1',
    if (other != 0) '$other bids failed with something other than OUTBID',
    if (outbid.isNotEmpty && !namedWinner) 'an OUTBID named another leader',
    if (added != 1) 'ledger grew by $added rows, expected 1',
    if (added == 1 && !rowIsWinner) "the new ledger row isn't the winner's",
  ];
  return _verdict(failures, '✓ exactly one winner');
}

/// N bids spread across ±[window] around the close.
Future<bool> _closeRace(
  Client reader,
  UuidValue lotId,
  List<_Bidder> bidders,
  Duration window,
) async {
  final start = await _timedDetail(reader, lotId);
  final closeAt = start.detail.closeAt;
  final offset = start.clockOffset;
  final lead = closeAt.difference(start.serverNow);
  if (lead < window + const Duration(seconds: 2)) {
    stderr.writeln(
      'race: the auction closes in ${lead.inMilliseconds} ms; '
      'need more than ${window.inMilliseconds} ms plus 2 s to set up',
    );
    return false;
  }
  if (lead > const Duration(minutes: 15)) {
    stderr.writeln(
      'race: the auction closes in ${lead.inMinutes} min; '
      'pick one closing within 15 min',
    );
    return false;
  }
  stdout.writeln(
    'close at ${closeAt.toIso8601String()} '
    '(in ${lead.inSeconds} s, clock offset ${offset.inMilliseconds} ms)',
  );

  // The freshest state any bid has seen, so each bid is aimed at the
  // current version rather than all at one.
  var version = start.detail.lot.version;
  var price = start.detail.lot.currentPrice;
  final step = start.detail.lot.increments.first;
  final before = start.detail.ledger.length;

  final n = bidders.length;
  final span = window * 2;
  final shots = await Future.wait([
    for (var i = 0; i < n; i++)
      () async {
        // Target moment on the server's clock, then on ours.
        final target = closeAt
            .subtract(window)
            .add(Duration(microseconds: span.inMicroseconds * i ~/ (n - 1)));
        final wait = target.subtract(offset).difference(DateTime.now().toUtc());
        if (wait > Duration.zero) await Future<void>.delayed(wait);
        final sent = DateTime.now().toUtc().add(offset).difference(closeAt);
        final outcome = await bidders[i].bid(lotId, price + step, version);
        if (outcome.card case final card?) {
          if (card.version > version) {
            (version, price) = (card.version, card.currentPrice);
          }
        } else if (outcome.code == 'OUTBID') {
          final seen = outcome.context['version'] as int;
          if (seen > version) {
            (version, price) = (seen, outcome.context['currentPrice'] as int);
          }
        }
        return (sent: sent, outcome: outcome);
      }(),
  ]);

  stdout.writeln();
  for (final shot in shots) {
    final ms = shot.sent.inMilliseconds;
    final o = shot.outcome;
    stdout.writeln(
      '  ${'${ms >= 0 ? '+' : ''}$ms'.padLeft(5)} ms  '
      '${o.bidder.name.padRight(8)} ${o.accepted ? 'accepted ${_rupiah(o.amount)}' : o.code}',
    );
  }

  // Wait for the auction-close sweep to settle the lot.
  final settleBy = DateTime.now().add(const Duration(seconds: 60));
  var after = await reader.lot.detail(lotId);
  while (after.lot.status == 'OPEN' && DateTime.now().isBefore(settleBy)) {
    await Future<void>.delayed(const Duration(seconds: 1));
    after = await reader.lot.detail(lotId);
  }

  final outcomes = [for (final s in shots) s.outcome];
  final accepted = outcomes.where((o) => o.accepted).length;
  final outbid = outcomes.where((o) => o.code == 'OUTBID').length;
  final closed = outcomes.where((o) => o.code == 'LOT_CLOSED').length;
  final other = outcomes.length - accepted - outbid - closed;
  final added = after.ledger.length - before;
  final late = [
    for (final e in after.ledger)
      if (!e.placedAt.isBefore(closeAt)) e,
  ];
  final last = after.ledger.where((e) => !e.retracted).lastOrNull;
  final settled = switch (after.lot.status) {
    'SOLD' =>
      last != null &&
          after.lot.winnerName == last.bidderName &&
          after.lot.leaderId == last.participantId &&
          after.lot.finalPrice == last.amount,
    'PASSED' => last == null,
    _ => false,
  };

  stdout
    ..writeln()
    ..writeln('$n bids within ±${window.inMilliseconds} ms of the close')
    ..writeln('  accepted   : ${_pad(accepted)}(before close)')
    ..writeln('  OUTBID     : ${_pad(outbid)}(lost a race before close)')
    ..writeln('  LOT_CLOSED : ${_pad(closed)}(at or after close)')
    ..writeln('  other      : $other${_codes(outcomes)}')
    ..writeln(
      'ledger rows added: $added, dated at or after close: ${late.length}',
    )
    ..writeln(
      'lot ${after.lot.status}'
      '${after.lot.winnerName == null ? '' : ' to ${after.lot.winnerName} '
                'at ${_rupiah(after.lot.finalPrice ?? 0)}'}',
    );

  final failures = [
    if (other != 0) '$other bids failed with something unexpected',
    if (added != accepted)
      'ledger grew by $added rows for $accepted accepted bids',
    if (late.isNotEmpty) '${late.length} ledger rows dated at or after close',
    if (after.lot.status == 'OPEN') 'the lot was still OPEN 60 s after close',
    if (after.lot.status != 'OPEN' && !settled)
      "the lot didn't close on its last valid bid",
  ];
  return _verdict(failures, '✓ nothing landed after the close');
}

/// The first OPEN lot of the auction with join [code].
Future<UuidValue> _firstOpenLot(Client client, String code) async {
  final board = await client.auction.board(code);
  final lot = board.lots.where((l) => l.status == 'OPEN').firstOrNull;
  if (lot == null) throw const FormatException('the auction has no OPEN lot');
  return lot.lotId;
}

/// The lot's detail with the server's clock offset from ours, taken at the
/// midpoint of the call.
Future<({LotDetail detail, DateTime serverNow, Duration clockOffset})>
_timedDetail(Client client, UuidValue lotId) async {
  final sent = DateTime.now().toUtc();
  final detail = await client.lot.detail(lotId);
  final received = DateTime.now().toUtc();
  final midpoint = sent.add(received.difference(sent) ~/ 2);
  return (
    detail: detail,
    serverNow: detail.serverNow,
    clockOffset: detail.serverNow.difference(midpoint),
  );
}

bool _verdict(List<String> failures, String success) {
  if (failures.isEmpty) {
    stdout.writeln(success);
    return true;
  }
  for (final failure in failures) {
    stdout.writeln('✗ $failure');
  }
  return false;
}

String _pad(int count) => count.toString().padRight(4);

/// The unexpected error codes among [outcomes], e.g. `   (NOT_PARTICIPANT ×2)`.
String _codes(List<_Outcome> outcomes) {
  final counts = <String, int>{};
  for (final o in outcomes) {
    if (o.accepted || o.code == 'OUTBID' || o.code == 'LOT_CLOSED') continue;
    counts.update(o.code!, (n) => n + 1, ifAbsent: () => 1);
  }
  if (counts.isEmpty) return '';
  return '   (${[for (final e in counts.entries) '${e.key} ×${e.value}'].join(', ')})';
}

/// [amount] as the board shows it, e.g. `Rp 250.000`.
String _rupiah(int amount) {
  final digits = amount.toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    groups.insert(0, digits.substring(end - 3 < 0 ? 0 : end - 3, end));
  }
  return 'Rp ${groups.join('.')}';
}

/// One race participant with its own connection.
class _Bidder {
  _Bidder(this.client, JoinResult joined)
    : id = joined.participantId,
      key = joined.participantKey,
      name = joined.displayName;

  final Client client;
  final UuidValue id;
  final String key;
  final String name;

  /// Bids [amount] at [expectedVersion]; never throws a domain error.
  Future<_Outcome> bid(UuidValue lotId, int amount, int expectedVersion) async {
    try {
      final card = await client.lot.placeBid(
        lotId,
        id,
        key,
        amount,
        expectedVersion,
        const Uuid().v7obj(),
      );
      return _Outcome(this, amount, card: card);
    } on TaroDomainException catch (e) {
      return _Outcome(this, amount, code: e.code, context: _decode(e.context));
    } on Object catch (e) {
      return _Outcome(this, amount, code: e.runtimeType.toString());
    }
  }

  static Map<String, Object?> _decode(String? json) =>
      json == null ? const {} : (jsonDecode(json) as Map).cast();
}

/// What one bid came back with: a card, or an error code and its context.
class _Outcome {
  _Outcome(
    this.bidder,
    this.amount, {
    this.card,
    this.code,
    this.context = const {},
  });

  final _Bidder bidder;
  final int amount;
  final LotCard? card;
  final String? code;
  final Map<String, Object?> context;

  bool get accepted => card != null;
}

enum _Mode { bid, closeRace }

class _Options {
  _Options({
    required this.host,
    required this.code,
    required this.lotId,
    required this.bidders,
    required this.mode,
    required this.window,
  });

  factory _Options.parse(List<String> arguments) {
    final values = <String, String>{};
    for (var i = 0; i < arguments.length; i++) {
      final argument = arguments[i];
      if (!argument.startsWith('--')) {
        throw FormatException('unexpected argument "$argument"');
      }
      final eq = argument.indexOf('=');
      if (eq > 0) {
        values[argument.substring(2, eq)] = argument.substring(eq + 1);
      } else if (i + 1 < arguments.length) {
        values[argument.substring(2)] = arguments[++i];
      } else {
        throw FormatException('$argument needs a value');
      }
    }
    final unknown = values.keys.toSet()
      ..removeAll(['host', 'code', 'lot', 'bidders', 'mode', 'window-ms']);
    if (unknown.isNotEmpty) {
      throw FormatException('unknown option --${unknown.first}');
    }

    var host =
        values['host'] ?? (throw const FormatException('--host is required'));
    if (!host.endsWith('/')) host = '$host/';
    final code =
        values['code'] ?? (throw const FormatException('--code is required'));
    final bidders = int.tryParse(values['bidders'] ?? '20');
    if (bidders == null || bidders < 2 || bidders > _maxBidders) {
      throw const FormatException('--bidders must be 2…$_maxBidders');
    }
    final windowMs = int.tryParse(values['window-ms'] ?? '300');
    if (windowMs == null || windowMs <= 0) {
      throw const FormatException('--window-ms must be above 0');
    }
    final mode = switch (values['mode'] ?? 'bid') {
      'bid' => _Mode.bid,
      'close-race' => _Mode.closeRace,
      final other => throw FormatException('unknown --mode "$other"'),
    };
    final lot = values['lot'];
    return _Options(
      host: host,
      code: code,
      lotId: lot == null ? null : UuidValue.withValidation(lot),
      bidders: bidders,
      mode: mode,
      window: Duration(milliseconds: windowMs),
    );
  }

  static const usage =
      '''
usage: dart run tool/race.dart --host <url> --code <join code> [options]
  --lot <id>        the lot to race on (default: the first OPEN lot)
  --bidders <n>     bidders, 2…$_maxBidders (default: 20)
  --mode <mode>     bid (default) or close-race
  --window-ms <ms>  close-race: spread bids ± this around the close (default: 300)''';

  final String host;
  final String code;
  final UuidValue? lotId;
  final int bidders;
  final _Mode mode;
  final Duration window;
}
