import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

ProjectionRebuilder rebuilderFor(EventStore eventStore, {int batchSize = 3}) =>
    ProjectionRebuilder(
      CronDispatcher(
        eventStore: eventStore,
        subscriptions: SubscriptionManager(eventStore.adapter),
        batchSize: batchSize,
      ),
    );

void main() {
  for (final mode in ConsistencyMode.values) {
    group('rebuild after transfers, ${mode.name}', () {
      late TransferHarness h;
      late TotalsProjection live;

      setUp(() async {
        h = TransferHarness(mode);
        live = TotalsProjection(TotalsDb(), processedEvents: h.processedEvents);
        h.bus.subscribe(live);
        await h.openWallets();
        await h.requestTransfer(cents: 30, fee: 5);
        await h.dispatcher.dispatch(DepositMoney(h.to, 7));
      });

      test('a rebuilt projection matches the live one', () async {
        final before = live.db.snapshot();
        expect(live.db.counts, {
          'WalletOpened': 2,
          'MoneyWithdrawn': 1,
          'MoneyDeposited': 2,
          'FeeCharged': 1,
        });

        final result = await rebuilderFor(h.eventStore).rebuild(live);

        expect(result.completed, isTrue, reason: '${result.error}');
        expect(result.eventsProcessed, 8);
        expect(result.passes, 3);
        expect(live.db.snapshot(), before);
        expect(live.hooks, ['start', 'complete']);
      });

      test('a new projection rebuilt from the store matches', () async {
        final fresh = TotalsProjection(
          TotalsDb(),
          processedEvents: LocalProvider().createProcessedEventStore(),
        );

        await rebuilderFor(h.eventStore).rebuild(fresh);

        expect(fresh.db.snapshot(), live.db.snapshot());
      });

      test('a rebuild repairs a corrupted read model', () async {
        final before = live.db.snapshot();
        live.db.cents['MoneyDeposited'] = 999;
        live.db.counts.remove('FeeCharged');

        await rebuilderFor(h.eventStore).rebuild(live);

        expect(live.db.snapshot(), before);
      });
    });
  }

  group('ProjectionRebuilder', () {
    late Store s;
    late TotalsProjection projection;
    late List<DomainEvent> events;

    setUp(() async {
      s = Store();
      projection = TotalsProjection(
        TotalsDb(),
        processedEvents: s.processedEvents,
      );
      events = await s.deposit([1, 2, 3, 4, 5]);
    });

    test('stops at a failing event by default', () async {
      projection.failOn = (e) => e.id == events[2].id ? domainError() : null;

      final result = await rebuilderFor(s.eventStore).rebuild(projection);

      expect(result.completed, isFalse);
      expect(result.error, isA<InvalidAggregateStateError>());
      expect(result.eventsProcessed, 2);
      expect(projection.hooks, ['start']);
      expect(await s.deadLetters.count(), 0);
    });

    test('continueOnError skips failing events', () async {
      projection.failOn = (e) => e.id == events[2].id ? domainError() : null;

      final result = await rebuilderFor(
        s.eventStore,
      ).rebuild(projection, continueOnError: true);

      expect(result.completed, isTrue);
      expect(result.eventsProcessed, 4);
      expect(result.skipped.single.event.eventId, events[2].id);
      expect(projection.db.cents, {'MoneyDeposited': 12});
      expect(projection.hooks, ['start', 'complete']);
    });

    test('without resetIdempotency only unhandled events replay', () async {
      for (final event in events.take(2)) {
        await projection.handle(event);
      }

      final result = await rebuilderFor(
        s.eventStore,
      ).rebuild(projection, resetIdempotency: false, callHooks: false);

      expect(result.eventsProcessed, 5);
      expect(projection.db.cents, {'MoneyDeposited': 15});
      expect(projection.db.counts, {'MoneyDeposited': 5});
      expect(projection.hooks, isEmpty);
    });

    test('maxPasses leaves the rebuild unfinished', () async {
      final result = await rebuilderFor(
        s.eventStore,
        batchSize: 1,
      ).rebuild(projection, maxPasses: 2);

      expect(result.completed, isFalse);
      expect(result.error, isNull);
      expect(result.eventsProcessed, 2);
      expect(projection.hooks, ['start']);
    });

    test('rebuildShards rebuilds every shard on its own', () async {
      final dbs = [TotalsDb(), TotalsDb()];
      final shards = [
        for (var i = 0; i < 2; i++)
          TotalsShard(
            dbs[i],
            processedEvents: s.processedEvents,
            shardIndex: i,
            shardCount: 2,
          ),
      ];
      for (final event in events) {
        for (final shard in shards) {
          await shard.handle(event);
        }
      }
      dbs[0].cents['MoneyDeposited'] = -1;

      final result = await rebuilderFor(s.eventStore).rebuildShards(shards);

      expect(result.allCompleted, isTrue);
      expect(dbs[0].eventIds.length + dbs[1].eventIds.length, events.length);
      expect(
        (dbs[0].cents['MoneyDeposited'] ?? 0) +
            (dbs[1].cents['MoneyDeposited'] ?? 0),
        15,
      );
      // Each shard's records stay under the shared projection name.
      expect(await s.processedEvents.count('totals'), 5);
    });

    test('rebuildAll reports each projection', () async {
      final other = _Renamed(TotalsDb(), s.processedEvents)
        ..failOn = (_) => retryableError();

      final result = await rebuilderFor(
        s.eventStore,
      ).rebuildAll([projection, other]);

      expect(
        [for (final r in result.results) r.projection],
        ['totals', 'renamed'],
      );
      expect(result.allCompleted, isFalse);
      expect(result.failed.single.projection, 'renamed');
    });
  });
}

class _Renamed extends TotalsProjection {
  _Renamed(super.db, ProcessedEventStore processed)
    : super(processedEvents: processed);

  @override
  String get name => 'renamed';
}
