import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('DomainEvent', () {
    test('envelope defaults start a new trace', () {
      final before = DateTime.timestamp();
      final event = MoneyDeposited(cents: 5);
      expect(event.id.isV7, isTrue);
      expect(event.correlationId.isV7, isTrue);
      expect(event.correlationId, isNot(event.id));
      expect(event.causationId, isNull);
      expect(event.metadata, isEmpty);
      expect(event.eventVersion, '1.0.0');
      expect(event.occurredAt.isUtc, isTrue);
      expect(event.occurredAt.isBefore(before), isFalse);
    });

    test('each event gets its own ID', () {
      expect(MoneyDeposited(cents: 1).id, isNot(MoneyDeposited(cents: 1).id));
    });

    test('inherits tracing IDs and metadata from the execution context', () {
      final command = Deposit(cents: 5, metadata: {'userId': 'u1'});
      final event = ExecutionContext.run(
        ExecutionContext.forCommand(command),
        () => MoneyDeposited(cents: 5),
      );
      expect(event.correlationId, command.correlationId);
      expect(event.causationId, command.id);
      expect(event.metadata, {'userId': 'u1'});
    });

    test('metadata is immutable', () {
      final event = ExecutionContext.run(
        ExecutionContext(
          correlationId: AccountId.generate().value,
          metadata: {'tenant': 't1'},
        ),
        () => MoneyDeposited(cents: 1),
      );
      expect(() => event.metadata['x'] = 1, throwsUnsupportedError);
    });

    test('withEnvelope assigns a given envelope', () {
      final envelope = EventEnvelope(
        id: UuidValue.fromString(v7),
        correlationId: UuidValue.fromString(v4),
        causationId: UuidValue.fromString(v4),
        metadata: {'n': 1},
        occurredAt: DateTime.utc(2026, 10, 11),
      );
      final event = DomainEvent.withEnvelope(
        envelope,
        () => MoneyDeposited(cents: 3),
      );
      expect(event.envelope, same(envelope));
      expect(event.cents, 3);
    });

    test('withEnvelope gives the envelope to one event only', () {
      final envelope = EventEnvelope.fromContext();
      expect(
        () => DomainEvent.withEnvelope(envelope, () {
          MoneyDeposited(cents: 1);
          return MoneyDeposited(cents: 2);
        }),
        throwsStateError,
      );
    });
  });

  group('EventEnvelope', () {
    test('requires a UUIDv7 event ID', () {
      expect(
        () => EventEnvelope(
          id: UuidValue.fromString(v4),
          correlationId: UuidValue.fromString(v4),
          occurredAt: DateTime.timestamp(),
        ),
        throwsA(isA<InvalidEventIdError>()),
      );
    });

    test('rejects non-primitive metadata', () {
      expect(
        () => EventEnvelope(
          id: UuidValue.fromString(v7),
          correlationId: UuidValue.fromString(v4),
          metadata: {
            'list': [1],
          },
          occurredAt: DateTime.timestamp(),
        ),
        throwsArgumentError,
      );
    });

    test('stores occurredAt in UTC', () {
      final local = DateTime(2026, 10, 11, 9);
      final envelope = EventEnvelope(
        id: UuidValue.fromString(v7),
        correlationId: UuidValue.fromString(v4),
        occurredAt: local,
      );
      expect(envelope.occurredAt.isUtc, isTrue);
      expect(envelope.occurredAt, local.toUtc());
    });

    test('JSON round trip', () {
      final envelope = ExecutionContext.run(
        ExecutionContext(
          correlationId: UuidValue.fromString(v4),
          causationId: UuidValue.fromString(v7),
          metadata: {'userId': 'u1', 'admin': false},
        ),
        EventEnvelope.fromContext,
      );
      final json = envelope.toJson();
      expect(json['occurredAt'], endsWith('Z'));
      expect(EventEnvelope.fromJson(json), envelope);
    });

    final valid = EventEnvelope.fromContext().toJson();

    final invalid = <String, (Map<String, Object?>, Matcher)>{
      'event ID': ({...valid, 'eventId': 'x'}, isA<InvalidEventIdError>()),
      'missing event ID': (
        {...valid}..remove('eventId'),
        isA<InvalidEventIdError>(),
      ),
      'v4 event ID': ({...valid, 'eventId': v4}, isA<InvalidEventIdError>()),
      'correlation ID': (
        {...valid, 'correlationId': 'x'},
        isA<InvalidCorrelationIdError>(),
      ),
      'causation ID': (
        {...valid, 'causationId': 42},
        isA<InvalidCausationIdError>(),
      ),
      'timestamp': (
        {...valid, 'occurredAt': 'yesterday'},
        isA<SerializationError>(),
      ),
      'metadata': ({...valid, 'metadata': 'x'}, isA<SerializationError>()),
    };
    invalid.forEach((name, testCase) {
      test('fromJson rejects a malformed $name', () {
        expect(() => EventEnvelope.fromJson(testCase.$1), throwsA(testCase.$2));
      });
    });
  });
}
