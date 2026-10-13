import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';
import 'package:test/test.dart';

import '../saga/fixtures.dart';

void main() {
  late ProcessedEventStore processed;

  setUp(() => processed = LocalProvider().createProcessedEventStore());

  group('Projection', () {
    late BalanceProjection projection;

    setUp(() => projection = BalanceProjection(processed));

    test('routes each event to its handler', () async {
      await projection.handle(WalletOpened(100));
      await projection.handle(MoneyWithdrawn(30));
      await projection.handle(MoneyDeposited(5));

      expect(projection.balance, 75);
      expect(await processed.count('balance'), 3);
    });

    test('handles each event once', () async {
      final event = MoneyDeposited(5);
      await projection.handle(event);
      await projection.handle(event);

      expect(projection.balance, 5);
      expect(await processed.exists('balance', 'balance', event.id), isTrue);
    });

    test('skips events with no handler and records them', () async {
      final event = TransferCompleted();
      await projection.handle(event);

      expect(projection.calls, isEmpty);
      expect(await processed.exists('balance', 'balance', event.id), isTrue);
    });

    test('an exact type wins over a supertype', () async {
      await projection.handle(FeeCharged(2));
      await projection.handle(MoneyRefunded(3));

      expect(projection.calls, ['FeeCharged', 'other:MoneyRefunded']);
    });

    test('wraps a handler error and does not record the event', () async {
      final event = MoneyWithdrawn(1);
      projection.failWith = StateError('db down');

      await expectLater(
        projection.handle(event),
        throwsA(
          isA<ProjectionHandlerFailedError>()
              .having((e) => e.retryable, 'retryable', isTrue)
              .having((e) => e.cause, 'cause', isStateError)
              .having((e) => e.context['projection'], 'projection', 'balance')
              .having((e) => e.context['eventId'], 'eventId', event.id.uuid),
        ),
      );
      expect(await processed.exists('balance', 'balance', event.id), isFalse);

      projection.failWith = null;
      await projection.handle(event);
      expect(projection.balance, -1);
    });

    test('rethrows framework errors as they are', () async {
      projection.failWith = OptimisticConcurrencyError('conflict');
      await expectLater(
        projection.handle(MoneyWithdrawn(1)),
        throwsA(isA<OptimisticConcurrencyError>()),
      );
    });

    test('reports the registered types', () {
      expect(projection.handledEventTypes, [
        WalletOpened,
        MoneyWithdrawn,
        MoneyDeposited,
        FeeCharged,
        WalletEvent,
      ]);
      expect(projection.handles(MoneyRefunded(1)), isTrue);
      expect(projection.handles(TransferCompleted()), isFalse);
    });

    test('rejects duplicate and unspecific registrations', () {
      expect(
        () => BalanceProjection(processed)..register<MoneyWithdrawn>(),
        throwsA(isA<InvalidConfigurationError>()),
      );
      expect(
        () => BalanceProjection(processed)..register<DomainEvent>(),
        throwsA(isA<InvalidConfigurationError>()),
      );
    });

    test('rebuild hooks do nothing by default', () async {
      await projection.onRebuildStart();
      await projection.onRebuildComplete();
    });

    test('runs inside the strong unit of work', () async {
      final provider = LocalProvider();
      final processed = provider.createProcessedEventStore();
      final projection = BalanceProjection(processed);
      final bus = InMemoryEventBus()..subscribe(projection);

      await expectLater(
        provider.createUnitOfWork().execute(() async {
          await bus.publish(MoneyDeposited(5));
          throw StateError('command fails later');
        }),
        throwsStateError,
      );
      expect(await processed.count('balance'), 0);
    });
  });

  group('ShardProjection', () {
    test('shardFor is FNV-1a', () {
      expect(ShardProjection.shardFor('', 1 << 32), 0x811c9dc5);
      expect(ShardProjection.shardFor('a', 1 << 32), 0xe40c292c);
      expect(ShardProjection.shardFor('foobar', 1 << 32), 0xbf9cf968);
      expect(ShardProjection.shardFor('foobar', 7), 0xbf9cf968 % 7);
    });

    test('each event goes to exactly one shard', () async {
      final shards = [
        for (var i = 0; i < 3; i++) WalletShard(processed, shardIndex: i),
      ];
      final bus = InMemoryEventBus();
      shards.forEach(bus.subscribe);
      final wallets = [for (var i = 0; i < 12; i++) WalletId.generate()];

      for (final wallet in wallets) {
        await bus.publish(TaggedDeposit(wallet, 1));
      }

      expect(shards.map((s) => s.name), [
        'wallets-shard-0',
        'wallets-shard-1',
        'wallets-shard-2',
      ]);
      expect(
        shards.expand((s) => s.seen).toSet(),
        wallets.map((w) => '$w').toSet(),
      );
      expect(shards.fold(0, (n, s) => n + s.seen.length), 12);
      for (final shard in shards) {
        for (final key in shard.seen) {
          expect(ShardProjection.shardFor(key, 3), shard.shardIndex);
        }
        expect(
          await processed.count('wallets', handlerInstance: shard.name),
          shard.seen.length,
        );
      }
      expect(await processed.count('wallets'), 12);
    });

    test('events without a shard key are not handled or recorded', () async {
      final shard = WalletShard(processed, shardIndex: 0, shardCount: 1);
      await shard.handle(MoneyDeposited(1));

      expect(shard.seen, isEmpty);
      expect(await processed.count('wallets'), 0);
    });

    test('rejects an invalid shard', () {
      for (final (index, count) in [(0, 0), (-1, 2), (2, 2)]) {
        expect(
          () => WalletShard(processed, shardIndex: index, shardCount: count),
          throwsA(isA<InvalidConfigurationError>()),
        );
      }
    });
  });
}

class BalanceProjection extends Projection {
  BalanceProjection(ProcessedEventStore processed)
    : super(processedEvents: processed) {
    on<WalletOpened>((e) => _track(e, () => balance = e.cents));
    on<MoneyWithdrawn>((e) => _track(e, () => balance -= e.cents));
    on<MoneyDeposited>((e) async {
      await Future<void>.delayed(Duration.zero);
      _track(e, () => balance += e.cents);
    });
    on<FeeCharged>((e) => _track(e, () {}));
    on<WalletEvent>((e) => calls.add('other:${e.eventName}'));
  }

  int balance = 0;
  final calls = <String>[];
  Object? failWith;

  @override
  String get name => 'balance';

  void register<E extends DomainEvent>() => on<E>((_) {});

  void _track(WalletEvent event, void Function() update) {
    if (failWith case final error?) throw error;
    calls.add(event.eventName);
    update();
  }
}

/// A deposit that names its wallet, for sharding.
class TaggedDeposit extends DomainEvent {
  TaggedDeposit(this.walletId, this.cents);

  final WalletId walletId;
  final int cents;

  @override
  String get eventName => 'TaggedDeposit';

  @override
  Map<String, Object?> toData() => {'walletId': '$walletId', 'cents': cents};
}

class WalletShard extends ShardProjection {
  WalletShard(
    ProcessedEventStore processed, {
    required super.shardIndex,
    super.shardCount = 3,
  }) : super(processedEvents: processed) {
    on<TaggedDeposit>((e) => seen.add('${e.walletId}'));
  }

  final seen = <String>[];

  @override
  String get projectionName => 'wallets';

  @override
  String? shardKey(DomainEvent event) => switch (event) {
    TaggedDeposit(:final walletId) => '$walletId',
    _ => null,
  };
}
