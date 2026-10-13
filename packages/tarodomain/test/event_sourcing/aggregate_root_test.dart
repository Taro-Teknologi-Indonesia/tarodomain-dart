import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('AggregateRoot', () {
    final id = AccountId.generate();

    test('starts empty at version 0', () {
      final account = BankAccount(id);
      expect(account.id, id);
      expect(account.version, 0);
      expect(account.committedVersion, 0);
      expect(account.hasUncommittedChanges, isFalse);
    });

    test('raise applies the event and queues it', () {
      final account = BankAccount.open(id, 'ann')..deposit(5);
      expect(account.owner, 'ann');
      expect(account.balance, 5);
      expect(account.version, 2);
      expect(account.committedVersion, 0);
      expect(account.hasUncommittedChanges, isTrue);
      expect(account.getUncommittedChanges(), [
        isA<AccountOpened>(),
        isA<FundsDeposited>(),
      ]);
    });

    test('getUncommittedChanges returns an unmodifiable copy', () {
      final account = BankAccount.open(id, 'ann');
      final changes = account.getUncommittedChanges();
      expect(() => changes.clear(), throwsUnsupportedError);
      account.deposit(1);
      expect(changes, hasLength(1));
    });

    test('markChangesAsCommitted clears the buffer and keeps the version', () {
      final account = BankAccount.open(id, 'ann')..deposit(5);
      account.markChangesAsCommitted();
      expect(account.hasUncommittedChanges, isFalse);
      expect(account.version, 2);
      expect(account.committedVersion, 2);

      account.deposit(1);
      expect(account.committedVersion, 2);
      expect(account.version, 3);
    });

    test('loadFromHistory replays without queueing', () {
      final account = BankAccount(id)
        ..loadFromHistory([
          AccountOpened(owner: 'ann'),
          FundsDeposited(cents: 2),
          FundsDeposited(cents: 3),
        ]);
      expect(account.balance, 5);
      expect(account.version, 3);
      expect(account.committedVersion, 3);
      expect(account.hasUncommittedChanges, isFalse);
    });

    test('loadFromHistory rejects an event outside the family', () {
      expect(
        () => BankAccount(id).loadFromHistory([UnrelatedHappened()]),
        throwsA(
          isA<MissingEventHandlerError>().having(
            (e) => e.context['eventType'],
            'eventType',
            'UnrelatedHappened',
          ),
        ),
      );
    });

    test('loadFromHistory refuses uncommitted changes', () {
      expect(
        () => BankAccount.open(id, 'ann').loadFromHistory([]),
        throwsStateError,
      );
    });

    test('events raised in an execution context carry its IDs', () {
      final context = ExecutionContext(
        correlationId: AccountId.generate().value,
        causationId: AccountId.generate().value,
      );
      final account = ExecutionContext.run(
        context,
        () => BankAccount.open(id, 'ann'),
      );
      final event = account.getUncommittedChanges().single;
      expect(event.correlationId, context.correlationId);
      expect(event.causationId, context.causationId);
    });

    test('restoreSnapshot sets state and version, then replay continues', () {
      final account = SnapshottableAccount(id)
        ..restoreSnapshot({'owner': 'ann', 'balance': 10}, 4)
        ..loadFromHistory([FundsDeposited(cents: 1)]);
      expect(account.owner, 'ann');
      expect(account.balance, 11);
      expect(account.version, 5);
    });

    test('toSnapshot captures the business state', () {
      final account = SnapshottableAccount.open(id, 'ann')..deposit(7);
      expect(account.toSnapshot(), {'owner': 'ann', 'balance': 7});
    });

    test('restoreSnapshot requires Snapshottable', () {
      expect(
        () => BankAccount(id).restoreSnapshot({}, 1),
        throwsA(isA<InvalidConfigurationError>()),
      );
    });

    test('restoreVersion rebuilds from state', () {
      final account = BankAccount.fromState(
        id,
        owner: 'ann',
        balance: 9,
        version: 3,
      );
      expect(account.version, 3);
      account.deposit(1);
      expect(account.committedVersion, 3);
      expect(account.balance, 10);
    });
  });
}
