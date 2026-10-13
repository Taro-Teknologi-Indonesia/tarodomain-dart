import 'package:bank_account/bank_account.dart';
import 'package:bank_account_serverpod_server/src/bank.dart';
import 'package:bank_account_serverpod_server/src/generated/protocol.dart';
import 'package:bank_account_serverpod_server/src/holders/account_holder.dart';
import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_serverpod_server/tarodomain_serverpod_server.dart'
    hide Protocol;
import 'package:test/test.dart';

import 'tables.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  // Commands run in real transactions, which the default per-test rollback
  // (one shared transaction) doesn't allow.
  withServerpod(
    'Given the bank on SQLite',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final bank = endpoints.bank;
      late Session session;

      setUp(() async {
        session = sessionBuilder.build();
        await clearTables(session);
      });

      for (final mode in ConsistencyMode.values) {
        group('with ${mode.name} commands by default', () {
          late TaroDomainServerpod taro;
          late List<Duration> scheduled;

          setUp(() {
            scheduled = [];
            taro = TaroDomainServerpod(
              bankServerDefinition(consistency: mode),
              scheduleCatchUp: (_, delay) async => scheduled.add(delay),
            )..install();
          });

          /// Delivers stored events the way the scheduled catch-up would,
          /// until sagas stop dispatching new commands.
          Future<void> catchUp() async {
            for (var i = 0; i < 5; i++) {
              await taro.runCatchUp(session);
            }
          }

          Future<AccountBalance?> balance(UuidValue id) =>
              bank.balance(sessionBuilder, id);

          test('strong commands reach the projection at once, eventual ones '
              'after catch-up', () async {
            final alice = await bank.openAccount(sessionBuilder, 'Alice');

            expect((await balance(alice))?.owner, 'Alice');

            await bank.deposit(sessionBuilder, alice, 10000);
            switch (mode) {
              case ConsistencyMode.strong:
                expect(scheduled, isEmpty);
                expect((await balance(alice))?.balanceCents, 10000);
              case ConsistencyMode.eventual:
                expect(scheduled, [Duration.zero]);
                expect((await balance(alice))?.balanceCents, 0);
            }

            await catchUp();
            expect((await balance(alice))?.balanceCents, 10000);
          });

          test('a transfer moves the money through the saga', () async {
            final alice = await bank.openAccount(sessionBuilder, 'Alice');
            final bob = await bank.openAccount(sessionBuilder, 'Bob');
            await bank.deposit(sessionBuilder, alice, 10000);

            final transferId = await bank.transfer(
              sessionBuilder,
              alice,
              bob,
              3000,
            );
            await catchUp();

            expect((await balance(alice))?.balanceCents, 7000);
            expect((await balance(bob))?.balanceCents, 3000);
            final runtime = taro.runtime(session);
            final transfer = await runtime
                .repository<MoneyTransfer, TransferId>()
                .load(TransferId.fromExisting(transferId.uuid));
            expect(transfer.status, TransferStatus.completed);
            expect(
              await runtime.sagaStore.count(status: SagaStatus.completed),
              1,
            );
          });

          test('a transfer without enough money fails', () async {
            final alice = await bank.openAccount(sessionBuilder, 'Alice');
            final bob = await bank.openAccount(sessionBuilder, 'Bob');

            final transferId = await bank.transfer(
              sessionBuilder,
              bob,
              alice,
              1,
            );
            await catchUp();

            final transfer = await taro
                .runtime(session)
                .repository<MoneyTransfer, TransferId>()
                .load(TransferId.fromExisting(transferId.uuid));
            expect(transfer.status, TransferStatus.failed);
            expect((await balance(bob))?.rejectedWithdrawals, 1);
          });

          test('framework errors reach the client as TaroDomainException', () {
            expect(
              bank.deposit(sessionBuilder, AccountId.generate().value, 100),
              throwsA(
                isA<TaroDomainException>()
                    .having((e) => e.code, 'code', 'AGGREGATE_NOT_FOUND')
                    .having((e) => e.category, 'category', 'domain'),
              ),
            );
          });

          group('the state-based AccountHolder', () {
            Future<AccountHolderRow?> row(UuidValue id) =>
                AccountHolderRow.db.findById(session, id);

            test('is stored as a row, and its events in its stream', () async {
              final id = await bank.registerHolder(
                sessionBuilder,
                'Alice',
                'alice@example.com',
              );
              await bank.changeHolderEmail(
                sessionBuilder,
                id,
                'alice@example.org',
              );

              final stored = (await row(id))!;
              expect(stored.email, 'alice@example.org');
              expect(stored.version, 2);
              final events = await taro
                  .runtime(session)
                  .eventStore
                  .loadStream('AccountHolder-${id.uuid}');
              expect(
                [for (final e in events) e.eventName],
                ['HolderRegistered', 'HolderEmailChanged'],
              );
            });

            test('rejects a save from a stale copy', () async {
              final id = await bank.registerHolder(
                sessionBuilder,
                'Alice',
                'alice@example.com',
              );
              final repository = taro
                  .runtime(session)
                  .repository<AccountHolder, HolderId>();
              final holderId = HolderId.fromExisting(id.uuid);
              final first = await repository.load(holderId);
              final second = await repository.load(holderId);

              await repository.save(first..changeEmail('first@example.com'));
              await expectLater(
                repository.save(second..changeEmail('second@example.com')),
                throwsA(isA<OptimisticConcurrencyError>()),
              );

              expect((await row(id))?.email, 'first@example.com');
              expect(
                await taro
                    .runtime(session)
                    .eventStoreAdapter
                    .getStreamVersion('AccountHolder-${id.uuid}'),
                2,
              );
            });

            test('rejects registering twice', () async {
              final id = HolderId.generate();
              await taro
                  .runtime(session)
                  .dispatch(RegisterHolder(id, 'Alice', 'a@example.com'));

              await expectLater(
                taro
                    .runtime(session)
                    .dispatch(RegisterHolder(id, 'Mallory', 'm@example.com')),
                throwsA(isA<AggregateAlreadyExistsError>()),
              );
            });
          });
        });
      }

      test('under strong consistency a failing projection rolls the command '
          'back', () async {
        final taro = TaroDomainServerpod(
          bankServerDefinition(consistency: ConsistencyMode.strong),
        )..install();
        final alice = await bank.openAccount(sessionBuilder, 'Alice');
        // The projection can't find the row to update.
        await AccountBalance.db.deleteWhere(
          session,
          where: (t) => t.accountId.equals(alice),
        );

        await expectLater(
          bank.deposit(sessionBuilder, alice, 100),
          throwsA(
            isA<TaroDomainException>().having(
              (e) => e.code,
              'code',
              'PROJECTION_HANDLER_FAILED',
            ),
          ),
        );

        final account = await taro
            .runtime(session)
            .repository<BankAccount, AccountId>()
            .load(AccountId.fromExisting(alice.uuid));
        expect(account.version, 1);
        expect(account.balanceCents, 0);
      });

      test('an invalid projection stops the server at startup', () async {
        final taro = TaroDomainServerpod(
          TaroDomain.builder()
              .projection(
                (c) => _StrayProjection(processedEvents: c.processedEvents),
              )
              .build(),
        );

        await expectLater(
          taro.validate(session.serverpod),
          throwsA(isA<InvalidConfigurationError>()),
        );
      });
    },
  );
}

/// An event no definition registers.
final class _Stray extends DomainEvent {
  @override
  String get eventName => 'Stray';

  @override
  Map<String, Object?> toData() => const {};
}

final class _StrayProjection extends Projection {
  _StrayProjection({required super.processedEvents}) {
    on<_Stray>((_) {});
  }

  @override
  String get name => 'stray';
}
