import 'dart:async';

import 'package:tarodomain/tarodomain.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

/// Creates the subject of a contract suite. It is called once per test and
/// must return an instance over empty storage.
typedef ContractFactory<T> = FutureOr<T> Function();

/// Builds [SerializedEvent]s whose IDs increase by one millisecond each, so
/// append order and event ID order agree.
final class TestEvents {
  int _millis = DateTime.timestamp().millisecondsSinceEpoch;
  int _streams = 0;

  /// A fresh UUIDv7, later than every one this instance made before.
  UuidValue nextId() => const Uuid().v7obj(config: V7Options(++_millis, null));

  /// Two UUIDv7s from the same millisecond, where the first sorts after the
  /// second.
  (UuidValue, UuidValue) descendingIdsInOneMillisecond() {
    final millis = ++_millis;
    return (
      const Uuid().v7obj(config: V7Options(millis, List.filled(10, 0xff))),
      const Uuid().v7obj(config: V7Options(millis, List.filled(10, 0x00))),
    );
  }

  /// A fresh aggregate stream ID in [category].
  String streamId([String category = 'Account']) =>
      '$category-${nextId().uuid}';

  /// A fresh category name, unique within this instance.
  String category() => 'Category${++_streams}';

  /// An event with a fresh ID, or [id].
  SerializedEvent event({
    UuidValue? id,
    String type = 'TestEvent',
    UuidValue? correlationId,
    UuidValue? causationId,
    Map<String, Object?> data = const {},
  }) => SerializedEvent(
    eventType: type,
    eventVersion: '1.0.0',
    envelope: EventEnvelope(
      id: id ?? nextId(),
      correlationId: correlationId ?? nextId(),
      causationId: causationId,
      metadata: const {'tenant': 't1'},
      occurredAt: DateTime.timestamp(),
    ),
    data: data,
  );

  /// [count] events with fresh, increasing IDs. Each one's data holds its
  /// index `n`.
  List<SerializedEvent> events(int count, {UuidValue? correlationId}) => [
    for (var n = 0; n < count; n++)
      event(correlationId: correlationId, data: {'n': n}),
  ];
}

/// Waits long enough that timestamps recorded before and after differ.
Future<void> tick() => Future<void>.delayed(const Duration(milliseconds: 5));

/// The IDs of [events], to compare lists of events by identity.
List<UuidValue> idsOf(Iterable<SerializedEvent> events) => [
  for (final e in events) e.eventId,
];
