import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart';
import 'package:tarodomain_testing/tarodomain_testing.dart';
import 'package:test/test.dart';

import 'tables.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given the Serverpod provider on PostgreSQL',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, _) {
      late Session session;
      late TestEvents events;

      setUp(() async {
        session = sessionBuilder.build();
        await clearTaroTables(session);
        events = TestEvents();
      });

      /// Appends one event to a new stream in a transaction that stays open
      /// until the returned function is called, and waits until the append
      /// ran.
      Future<Future<void> Function()> appendAndHold(
        EventStoreAdapter store,
        String streamId,
      ) async {
        final appended = Completer<void>();
        final release = Completer<void>();
        final done = ServerpodUnitOfWork(session).execute(() async {
          await store.appendToStream(streamId, events.events(1), 0);
          appended.complete();
          await release.future;
        });
        await appended.future;
        return () {
          release.complete();
          return done;
        };
      }

      group('global order', () {
        test('a cursor reader sees every event exactly once while appenders '
            'hold their transactions open', () async {
          final store = ServerpodEventStoreAdapter(session);
          final random = Random(7);
          final appended = <UuidValue>[];
          var appending = true;
          final appenders = Future.wait([
            for (var i = 0; i < 12; i++)
              () async {
                await Future<void>.delayed(
                  Duration(milliseconds: random.nextInt(60)),
                );
                final batch = events.events(1 + i % 3);
                appended.addAll(idsOf(batch));
                final streamId = events.streamId();
                if (i.isEven) {
                  await ServerpodUnitOfWork(session).execute(() async {
                    await store.appendToStream(streamId, batch, 0);
                    await Future<void>.delayed(
                      Duration(milliseconds: random.nextInt(120)),
                    );
                  });
                } else {
                  await store.appendToStream(streamId, batch, 0);
                }
              }(),
          ]).whenComplete(() => appending = false);

          final seen = <UuidValue>[];
          UuidValue? cursor;
          Future<int> read() async {
            final page = await store.loadAll(afterEventId: cursor, maxCount: 4);
            seen.addAll(idsOf(page));
            if (page.isNotEmpty) cursor = page.last.eventId;
            return page.length;
          }

          while (appending) {
            await read();
            await Future<void>.delayed(const Duration(milliseconds: 3));
          }
          await appenders;
          while (await read() > 0) {}

          expect(seen.toSet(), hasLength(seen.length), reason: 'duplicates');
          expect(seen.toSet(), appended.toSet());
        });

        test(
          'an event committed late is positioned after one committed '
          'earlier, so a cursor past the earlier one still reads it',
          () async {
            final store = ServerpodEventStoreAdapter(session);
            final early = events.streamId();
            final commit = await appendAndHold(store, early);
            final late = events.events(1);
            await store.appendToStream(events.streamId(), late, 0);

            final firstRead = await store.loadAll();
            await commit();
            final secondRead = await store.loadAll(
              afterEventId: firstRead.last.eventId,
            );

            expect(idsOf(firstRead), idsOf(late));
            expect(secondRead, hasLength(1));
            expect(secondRead.single.eventId, isNot(late.single.eventId));
          },
        );

        test(
          'reads inside a unit of work see only positioned events',
          () async {
            final store = ServerpodEventStoreAdapter(session);
            final appended = events.events(1);

            await ServerpodUnitOfWork(session).execute(() async {
              await store.appendToStream(events.streamId(), appended, 0);
              expect(await store.loadAll(), isEmpty);
            });

            expect(idsOf(await store.loadAll()), idsOf(appended));
          },
        );

        test('concurrent readers racing appenders never fail and together '
            'position every event', () async {
          final store = ServerpodEventStoreAdapter(session);
          final appended = <UuidValue>[];
          var appending = true;
          final appenders = Future.wait([
            for (var i = 0; i < 8; i++)
              () async {
                for (var j = 0; j < 5; j++) {
                  final batch = events.events(2);
                  appended.addAll(idsOf(batch));
                  await store.appendToStream(events.streamId(), batch, 0);
                }
              }(),
          ]).whenComplete(() => appending = false);

          // Every read runs the sequencer, so these fight over the counter.
          // A read that loses must read what the winner positioned instead
          // of retrying until it throws.
          final readers = Future.wait([
            for (var i = 0; i < 16; i++)
              () async {
                while (appending) {
                  await store.loadAll(maxCount: 1);
                }
              }(),
          ]);
          await appenders;
          await readers;

          expect(idsOf(await store.loadAll()).toSet(), appended.toSet());
        });

        test('never reuses the position of a deleted event', () async {
          final store = ServerpodEventStoreAdapter(session);
          final kept = events.streamId();
          final deleted = events.streamId();
          await store.appendToStream(kept, events.events(1), 0);
          await store.appendToStream(deleted, events.events(1), 0);
          expect(await EventSequencer(session).run(), 2);
          await store.deleteStream(deleted);

          final next = events.events(1);
          await store.appendToStream(events.streamId(), next, 0);
          await EventSequencer(session).run();

          final row = await TaroEventRow.db.findFirstRow(
            session,
            where: (t) => t.eventId.equals(next.single.eventId),
          );
          expect(row?.position, 3);
        });

        test(
          'a subscription cursor survives the deletion of its event',
          () async {
            final store = ServerpodEventStoreAdapter(session);
            final deleted = events.streamId();
            final first = events.events(1);
            await store.appendToStream(deleted, first, 0);
            await store.subscribe('balances');
            final [read] = await store.loadAll();
            await store.ackSubscription('balances', read.eventId);
            await store.deleteStream(deleted);
            final next = events.events(1);
            await store.appendToStream(events.streamId(), next, 0);

            expect(
              idsOf(await store.loadAll(afterEventId: first.single.eventId)),
              idsOf(next),
            );
          },
        );

        test('ack never moves a cursor back', () async {
          final store = ServerpodEventStoreAdapter(session);
          final appended = events.events(3);
          await store.appendToStream(events.streamId(), appended, 0);
          await store.subscribe('balances');
          await store.loadAll();

          await store.ackSubscription('balances', appended[2].eventId);
          await store.ackSubscription('balances', appended[0].eventId);

          expect(
            (await store.getSubscription('balances'))?.lastSeen,
            appended[2].eventId,
          );
        });
      });

      group('ServerpodUnitOfWork', () {
        test('runs after-commit callbacks only after a commit', () async {
          final unitOfWork = ServerpodUnitOfWork(session);
          final calls = <String>[];

          await unitOfWork.execute(() async {
            await ServerpodUnitOfWork.afterCommit(session, () async {
              calls.add('committed');
            });
            expect(calls, isEmpty);
          });
          await expectLater(
            unitOfWork.execute(() async {
              await ServerpodUnitOfWork.afterCommit(session, () async {
                calls.add('rolled back');
              });
              throw StateError('rollback');
            }),
            throwsStateError,
          );
          await ServerpodUnitOfWork.afterCommit(session, () async {
            calls.add('no unit of work');
          });

          expect(calls, ['committed', 'no unit of work']);
        });

        test('is per session', () async {
          final other = sessionBuilder.build();
          await ServerpodUnitOfWork(session).execute(() async {
            expect(ServerpodUnitOfWork(session).isActive, isTrue);
            expect(ServerpodUnitOfWork(other).isActive, isFalse);
          });
        });

        test('join makes the adapters use an existing transaction', () async {
          final store = ServerpodEventStoreAdapter(session);
          final streamId = events.streamId();

          await expectLater(
            session.db.transaction(
              (transaction) =>
                  ServerpodUnitOfWork.join(session, transaction, () async {
                    expect(ServerpodUnitOfWork(session).isActive, isTrue);
                    await store.appendToStream(streamId, events.events(1), 0);
                    throw StateError('rollback');
                  }),
            ),
            throwsStateError,
          );

          expect(await store.streamExists(streamId), isFalse);
        });
      });

      test('LiveProjectionNotifier posts only after a commit', () async {
        final received = <String>[];
        session.messages.addListener(
          'balances',
          (message) => received.add((message as TaroDomainException).code),
        );
        final notifier = LiveProjectionNotifier(session);
        TaroDomainException update(String code) => TaroDomainException(
          code: code,
          category: 'domain',
          retryable: false,
          httpStatus: 200,
          message: 'update',
        );

        await ServerpodUnitOfWork(session).execute(() async {
          await notifier.post('balances', update('committed'));
          expect(received, isEmpty);
        });
        await expectLater(
          ServerpodUnitOfWork(session).execute(() async {
            await notifier.post('balances', update('rolled back'));
            throw StateError('rollback');
          }),
          throwsStateError,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(received, ['committed']);
      });

      group('FutureCallEventBus', () {
        test('schedules catch-up once per non-empty publish', () async {
          final delays = <Duration>[];
          final provider = ServerpodProvider(
            session,
            scheduleCatchUp: (s, delay) async {
              expect(s, same(session));
              delays.add(delay);
            },
          );
          final bus = provider.createEventBus(
            const EventBusConfig(consistency: ConsistencyMode.eventual),
          );

          await bus.publishAll(const []);
          await bus.publishAll([_Pinged(), _Pinged()]);

          expect(delays, [Duration.zero]);
        });

        test('the strong bus delivers to subscribers', () {
          final bus = ServerpodProvider(session).createEventBus(
            const EventBusConfig(consistency: ConsistencyMode.strong),
          );

          expect(bus, isA<SubscribableEventBus>());
        });
      });

      group('TaroDomainServerpod', () {
        late TaroDomainServerpod taro;

        setUp(() {
          taro = TaroDomainServerpod(
            TaroDomain.builder()
                .event<_Pinged>('Pinged', (_) => _Pinged())
                .build(),
          );
        });

        test('releases its lease after a run', () async {
          expect(await taro.runCatchUp(session), isEmpty);
          expect(await TaroLockRow.db.count(session), 0);
        });

        test('backs off while another server holds the lease', () async {
          await TaroLockRow.db.insertRow(
            session,
            TaroLockRow(
              name: 'tarodomain-catch-up',
              owner: 'other-server',
              lockedUntil: DateTime.timestamp().add(const Duration(hours: 1)),
            ),
          );

          expect(await taro.runCatchUp(session), isNull);
          expect(await taro.cleanup(session), isNotNull, reason: 'other job');
          expect(await TaroLockRow.db.count(session), 1);
        });

        test('takes over an expired lease', () async {
          await TaroLockRow.db.insertRow(
            session,
            TaroLockRow(
              name: 'tarodomain-catch-up',
              owner: 'crashed-server',
              lockedUntil: DateTime.timestamp().subtract(
                const Duration(seconds: 1),
              ),
            ),
          );

          expect(await taro.runCatchUp(session), isNotNull);
          expect(await TaroLockRow.db.count(session), 0);
        });

        test('cleanup deletes records older than their TTL', () async {
          final store = ServerpodCommandIdempotencyStore(session);
          await store.markProcessed(events.nextId(), 'Ping', 'PingHandler');

          final kept = await taro.cleanup(session);
          final later = await TaroDomainServerpod(
            taro.definition,
            clock: () => DateTime.timestamp().add(const Duration(days: 8)),
          ).cleanup(session);

          expect(kept, {
            'processedCommands': 0,
            'processedEvents': 0,
            'deadLetters': 0,
          });
          expect(later?['processedCommands'], 1);
        });

        test('install makes the instance current', () {
          taro.install();

          expect(TaroDomainServerpod.instance, same(taro));
        });
      });
    },
  );

  group('FrameworkError.toException', () {
    test('keeps the code, category and context', () {
      final error = OptimisticConcurrencyError(
        'Stream is at version 2',
        context: {'expectedVersion': 1, 'at': DateTime.utc(2026)},
      );

      final exception = error.toException();

      expect(exception.code, 'OPTIMISTIC_CONCURRENCY');
      expect(exception.category, 'concurrency');
      expect(exception.retryable, isTrue);
      expect(exception.httpStatus, 409);
      expect(exception.message, 'Stream is at version 2');
      expect(jsonDecode(exception.context!), {
        'expectedVersion': 1,
        'at': '2026-01-01 00:00:00.000Z',
      });
    });

    test('rethrowAsTaroDomainException converts only framework errors', () {
      expect(
        rethrowAsTaroDomainException(
          () async => throw CommandValidationError('bad'),
        ),
        throwsA(
          isA<TaroDomainException>().having((e) => e.code, 'code', isNotEmpty),
        ),
      );
      expect(
        rethrowAsTaroDomainException(() async => throw StateError('bug')),
        throwsStateError,
      );
    });
  });
}

final class _Pinged extends DomainEvent {
  _Pinged();

  @override
  String get eventName => 'Pinged';

  @override
  String get eventVersion => '1.0.0';

  @override
  Map<String, Object?> toData() => const {};
}
