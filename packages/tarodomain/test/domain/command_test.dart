import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'fixtures.dart';

void main() {
  group('Command', () {
    test('envelope defaults start a new trace', () {
      final command = Deposit(cents: 5);
      expect(command.id.isV7, isTrue);
      expect(command.correlationId, isNot(command.id));
      expect(command.causationId, isNull);
      expect(command.metadata, isEmpty);
      expect(command.timestamp.isUtc, isTrue);
    });

    test('keeps client-supplied IDs of any version', () {
      final command = Deposit(
        cents: 5,
        id: Command.parseId(v4),
        correlationId: Command.parseCorrelationId(v4),
      );
      expect(command.id.uuid, v4);
      expect(command.correlationId.uuid, v4);
    });

    test('a command created while handling an event is linked to it', () {
      final event = MoneyDeposited(cents: 5);
      final command = ExecutionContext.run(
        ExecutionContext.forEvent(event),
        () => Deposit(cents: 1),
      );
      expect(command.correlationId, event.correlationId);
      expect(command.causationId, event.id);
    });

    test('explicit envelope fields win over the context', () {
      final explicit = UuidValue.fromString(v4);
      final command = ExecutionContext.run(
        ExecutionContext.forEvent(MoneyDeposited(cents: 5)),
        () => Deposit(cents: 1, correlationId: explicit),
      );
      expect(command.correlationId, explicit);
    });

    test('parse helpers throw the spec error codes', () {
      expect(() => Command.parseId('x'), throwsA(isA<InvalidCommandIdError>()));
      expect(
        () => Command.parseCorrelationId('x'),
        throwsA(isA<InvalidCommandCorrelationIdError>()),
      );
      expect(
        () => Command.parseCausationId('x'),
        throwsA(isA<InvalidCommandCausationIdError>()),
      );
    });
  });

  group('withDerivedIds', () {
    final time = DateTime.utc(2026, 10, 11, 12);

    List<UuidValue> ids(String seed, [DateTime? at]) => Command.withDerivedIds(
      seed,
      () => [Deposit(cents: 1).id, Deposit(cents: 2).id],
      time: at ?? time,
    );

    /// The 48-bit millisecond timestamp of a UUIDv7.
    int timestampOf(UuidValue id) =>
        int.parse(id.uuid.replaceAll('-', '').substring(0, 12), radix: 16);

    test('derives the same IDs from the same seed, time and order', () {
      final first = ids('seed');
      expect(ids('seed'), first);
      expect(first[0], isNot(first[1]));
      expect(ids('other'), isNot(contains(first[0])));
    });

    test('derived IDs are UUIDv7 stamped with the given time', () {
      for (final id in ids('seed')) {
        expect(id.version, 7);
        expect(Uuid.isValidUUID(fromString: id.uuid), isTrue);
        expect(timestampOf(id), time.millisecondsSinceEpoch);
      }
      final later = ids('seed', time.add(const Duration(milliseconds: 1)));
      expect(later[0].uuid.compareTo(ids('seed')[1].uuid), greaterThan(0));
    });

    test('an explicit ID wins, and outside it IDs are fresh UUIDv7', () {
      final explicit = UuidValue.fromString(v4);
      final id = Command.withDerivedIds(
        'seed',
        () => Deposit(cents: 1, id: explicit).id,
        time: time,
      );
      expect(id, explicit);
      expect(Deposit(cents: 1).id.version, 7);
    });
  });
}
