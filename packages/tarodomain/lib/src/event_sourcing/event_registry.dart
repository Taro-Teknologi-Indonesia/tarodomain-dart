import '../domain/domain_event.dart';
import '../domain/serialized_event.dart';
import '../errors/error_codes.dart';
import '../errors/framework_error.dart';

/// Builds an event from its business fields. Called inside
/// [DomainEvent.withEnvelope], so the event gets its stored envelope.
typedef EventFactory<E extends DomainEvent> =
    E Function(Map<String, Object?> data);

/// Transforms an event's business fields from one schema version to the next.
typedef Upcaster = Map<String, Object?> Function(Map<String, Object?> data);

/// Maps stored event types to factories, and upgrades old schema versions
/// on read (spec §3.4).
///
/// Each event type has one factory, for its current version. Data stored
/// with an older version passes through the registered upcasters, one
/// version step at a time, until it reaches the current version:
///
/// ```dart
/// registry
///   ..register('MoneyDeposited', MoneyDeposited.fromData, version: '1.2.0')
///   ..registerUpcaster('MoneyDeposited', '1.0.0', '1.1.0', addCurrency)
///   ..registerUpcaster('MoneyDeposited', '1.1.0', '1.2.0', renameAmount);
/// ```
class EventRegistry {
  final _types = <String, _Registration>{};

  /// Registers [eventType] at its current [version], built by [fromData].
  ///
  /// Throws [DuplicateEventRegistrationError] if [eventType] is already
  /// registered.
  void register<E extends DomainEvent>(
    String eventType,
    EventFactory<E> fromData, {
    String version = '1.0.0',
  }) {
    if (_types[eventType]?.factory != null) {
      throw DuplicateEventRegistrationError(
        'Event type $eventType is already registered',
        context: {'eventType': eventType},
      );
    }
    (_types[eventType] ??= _Registration())
      ..factory = fromData
      ..version = version
      ..eventClass = _EventClass<E>();
  }

  /// Registers [upcast], which turns [eventType] data from [fromVersion] into
  /// [toVersion]. Upcasters may be registered before or after the type.
  ///
  /// Throws [DuplicateEventRegistrationError] if [eventType] already has an
  /// upcaster from [fromVersion].
  void registerUpcaster(
    String eventType,
    String fromVersion,
    String toVersion,
    Upcaster upcast,
  ) {
    final upcasters = (_types[eventType] ??= _Registration()).upcasters;
    if (upcasters.containsKey(fromVersion)) {
      throw DuplicateEventRegistrationError(
        'Event type $eventType already has an upcaster from $fromVersion',
        context: {'eventType': eventType, 'fromVersion': fromVersion},
      );
    }
    upcasters[fromVersion] = (toVersion: toVersion, upcast: upcast);
  }

  /// Whether [eventType] is registered. With [version], whether data of that
  /// version can be read: it is the current version, or upcasters lead from
  /// it to the current version.
  bool knows(String eventType, [String? version]) {
    final registration = _types[eventType];
    if (registration?.factory == null) return false;
    if (version == null) return true;
    try {
      _upcastPath(eventType, registration!, version);
      return true;
    } on EventVersionMismatchError {
      return false;
    }
  }

  /// Whether a registered event may be a [T]: the class of some
  /// registration is a subtype or a supertype of [T]. Startup validation
  /// uses it to find handlers for events that can never occur.
  bool mayProduce<T extends DomainEvent>() =>
      _types.values.any((r) => r.eventClass?.overlaps<T>() ?? false);

  /// The current version of [eventType], or null if it isn't registered.
  String? currentVersion(String eventType) => _types[eventType]?.version;

  /// Every registered event type.
  Iterable<String> get eventTypes =>
      _types.entries.where((e) => e.value.factory != null).map((e) => e.key);

  /// Upgrades [event] to the current version of its type, without building
  /// it.
  ///
  /// Throws [UnknownEventTypeError] if the type isn't registered, and
  /// [EventVersionMismatchError] if no upcaster chain leads from its version
  /// to the current one.
  SerializedEvent upcast(SerializedEvent event) {
    final registration = _registration(event.eventType);
    var current = event;
    for (final step in _upcastPath(
      event.eventType,
      registration,
      event.eventVersion,
    )) {
      final data = _guard(
        current,
        () => step.upcaster.upcast(Map.of(current.data)),
        'Upcaster from ${step.from}',
      );
      current = current.withData(step.upcaster.toVersion, data);
    }
    return current;
  }

  /// Upcasts [event] and builds the typed event with its stored envelope.
  ///
  /// Throws the errors of [upcast]; [EventVersionMismatchError] if the built
  /// event's name or version differs from the registration; and
  /// [SerializationError] if the factory or an upcaster throws something
  /// other than a [FrameworkError].
  DomainEvent deserialize(SerializedEvent event) {
    final upcasted = upcast(event);
    final factory = _registration(event.eventType).factory!;
    final built = _guard(
      upcasted,
      () => DomainEvent.withEnvelope(
        upcasted.envelope,
        () => factory(upcasted.data),
      ),
      'Factory',
    );
    if (built.eventName != upcasted.eventType ||
        built.eventVersion != upcasted.eventVersion) {
      throw EventVersionMismatchError(
        'Factory for ${upcasted.eventType}@${upcasted.eventVersion} built '
        '${built.eventName}@${built.eventVersion}',
        context: {
          'eventType': upcasted.eventType,
          'expectedVersion': upcasted.eventVersion,
          'actualType': built.eventName,
          'actualVersion': built.eventVersion,
        },
      );
    }
    return built;
  }

  _Registration _registration(String eventType) {
    final registration = _types[eventType];
    if (registration?.factory == null) {
      throw UnknownEventTypeError(
        'Event type $eventType is not registered',
        context: {'eventType': eventType},
      );
    }
    return registration!;
  }

  /// The upcasters leading from [version] to the current version.
  List<({String from, _Upcaster upcaster})> _upcastPath(
    String eventType,
    _Registration registration,
    String version,
  ) {
    final path = <({String from, _Upcaster upcaster})>[];
    var from = version;
    while (from != registration.version) {
      final upcaster = registration.upcasters[from];
      // A chain longer than the number of upcasters has a cycle.
      if (upcaster == null || path.length == registration.upcasters.length) {
        throw EventVersionMismatchError(
          'No upcaster chain for $eventType from $version to '
          '${registration.version}',
          context: {
            'eventType': eventType,
            'storedVersion': version,
            'currentVersion': registration.version,
          },
        );
      }
      path.add((from: from, upcaster: upcaster));
      from = upcaster.toVersion;
    }
    return path;
  }

  static T _guard<T>(SerializedEvent event, T Function() body, String what) {
    try {
      return body();
    } on FrameworkError {
      rethrow;
    } catch (error, stackTrace) {
      throw SerializationError(
        '$what for ${event.eventType}@${event.eventVersion} threw: $error',
        context: {
          'eventType': event.eventType,
          'eventVersion': event.eventVersion,
          'eventId': event.eventId.uuid,
        },
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

typedef _Upcaster = ({String toVersion, Upcaster upcast});

final class _EventClass<E extends DomainEvent> {
  bool overlaps<T>() => <E>[] is List<T> || <T>[] is List<E>;
}

class _Registration {
  EventFactory<DomainEvent>? factory;
  String? version;
  _EventClass? eventClass;
  final upcasters = <String, _Upcaster>{};
}
