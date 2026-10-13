import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import '../domain/fixtures.dart' show v4, v7;
import 'fixtures.dart';

SerializedEvent stored(
  String type,
  String version,
  Map<String, Object?> data,
) => SerializedEvent(
  eventType: type,
  eventVersion: version,
  envelope: EventEnvelope(
    id: UuidValue.fromString(v7),
    correlationId: UuidValue.fromString(v4),
    causationId: UuidValue.fromString(v4),
    metadata: {'userId': 'u1'},
    occurredAt: DateTime.utc(2026, 10, 11),
  ),
  data: data,
);

void main() {
  group('EventRegistry', () {
    late EventRegistry registry;

    setUp(() => registry = accountRegistry());

    test('deserializes the current version with the stored envelope', () {
      final event = stored('AccountOpened', '1.0.0', {'owner': 'ann'});
      final built = registry.deserialize(event);
      expect(
        built,
        isA<AccountOpened>().having((e) => e.owner, 'owner', 'ann'),
      );
      expect(built.envelope, event.envelope);
    });

    test('upcasts v1.0.0 to v1.2.0 through v1.1.0', () {
      final event = stored('FundsDeposited', '1.0.0', {'amount': 500});

      final upcasted = registry.upcast(event);
      expect(upcasted.eventVersion, '1.2.0');
      expect(upcasted.data, {'cents': 500, 'currency': 'USD'});
      expect(upcasted.envelope, event.envelope);

      final built = registry.deserialize(event) as FundsDeposited;
      expect(built.cents, 500);
      expect(built.currency, 'USD');
      expect(built.id, event.eventId);
    });

    test('upcasts from the middle of the chain', () {
      final event = stored('FundsDeposited', '1.1.0', {
        'amount': 7,
        'currency': 'EUR',
      });
      final built = registry.deserialize(event) as FundsDeposited;
      expect((built.cents, built.currency), (7, 'EUR'));
    });

    test('upcasters do not modify the stored data', () {
      final event = stored('FundsDeposited', '1.0.0', {'amount': 1});
      registry.upcast(event);
      expect(event.data, {'amount': 1});
    });

    test('rejects an unknown event type', () {
      expect(
        () => registry.deserialize(stored('Nope', '1.0.0', {})),
        throwsA(isA<UnknownEventTypeError>()),
      );
    });

    test('rejects a version with no upcaster chain', () {
      for (final version in ['0.9.0', '2.0.0']) {
        expect(
          () => registry.deserialize(stored('FundsDeposited', version, {})),
          throwsA(isA<EventVersionMismatchError>()),
          reason: version,
        );
      }
    });

    test('detects an upcaster cycle', () {
      final registry = EventRegistry()
        ..register('FundsDeposited', FundsDeposited.fromData, version: '1.2.0')
        ..registerUpcaster('FundsDeposited', '1.0.0', '1.1.0', (d) => d)
        ..registerUpcaster('FundsDeposited', '1.1.0', '1.0.0', (d) => d);
      expect(
        () => registry.upcast(stored('FundsDeposited', '1.0.0', {})),
        throwsA(isA<EventVersionMismatchError>()),
      );
    });

    test('rejects duplicate registrations', () {
      expect(
        () => registry.register('AccountOpened', AccountOpened.fromData),
        throwsA(isA<DuplicateEventRegistrationError>()),
      );
      expect(
        () => registry.registerUpcaster(
          'FundsDeposited',
          '1.0.0',
          '1.2.0',
          (d) => d,
        ),
        throwsA(isA<DuplicateEventRegistrationError>()),
      );
    });

    test('knows registered types and readable versions', () {
      expect(registry.knows('AccountOpened'), isTrue);
      expect(registry.knows('FundsDeposited', '1.0.0'), isTrue);
      expect(registry.knows('FundsDeposited', '1.2.0'), isTrue);
      expect(registry.knows('FundsDeposited', '0.1.0'), isFalse);
      expect(registry.knows('Nope'), isFalse);
      expect(registry.currentVersion('FundsDeposited'), '1.2.0');
      expect(
        registry.eventTypes,
        unorderedEquals(['AccountOpened', 'FundsDeposited']),
      );
    });

    test('a type with only upcasters is not known', () {
      final registry = EventRegistry()
        ..registerUpcaster('X', '1.0.0', '1.1.0', (d) => d);
      expect(registry.knows('X'), isFalse);
      expect(registry.eventTypes, isEmpty);
    });

    test('wraps a throwing factory in SerializationError', () {
      expect(
        () => registry.deserialize(stored('AccountOpened', '1.0.0', {})),
        throwsA(
          isA<SerializationError>().having(
            (e) => e.context['eventType'],
            'eventType',
            'AccountOpened',
          ),
        ),
      );
    });

    test('rejects a factory that builds a different event', () {
      final registry = EventRegistry()
        ..register('Renamed', AccountOpened.fromData);
      expect(
        () => registry.deserialize(stored('Renamed', '1.0.0', {'owner': 'x'})),
        throwsA(isA<EventVersionMismatchError>()),
      );
    });
  });

  group('SerializedEvent', () {
    test('round-trips through JSON', () {
      final event = FundsDeposited(cents: 3).serialize();
      expect(SerializedEvent.fromJson(event.toJson()), event);
      expect(event.eventType, 'FundsDeposited');
      expect(event.eventVersion, '1.2.0');
      expect(event.data, {'cents': 3, 'currency': 'USD'});
    });

    test('rejects malformed JSON', () {
      final json = FundsDeposited(cents: 3).serialize().toJson()
        ..remove('eventType');
      expect(
        () => SerializedEvent.fromJson(json),
        throwsA(isA<SerializationError>()),
      );
    });

    test('data is immutable', () {
      final event = FundsDeposited(cents: 3).serialize();
      expect(() => event.data['x'] = 1, throwsUnsupportedError);
    });
  });
}
