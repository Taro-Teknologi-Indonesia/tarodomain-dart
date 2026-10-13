import '../domain/domain_event.dart';

/// Delivers events to projections and sagas (spec §10.1).
abstract class EventBus {
  /// Name used in logs and errors.
  String get name;

  /// Delivers [events] in order.
  Future<void> publishAll(List<DomainEvent> events);

  /// Delivers one event; the same as `publishAll([event])`.
  Future<void> publish(DomainEvent event) => publishAll([event]);
}

/// How events reach their handlers (spec §15).
enum ConsistencyMode {
  /// In the same unit of work as the command.
  strong,

  /// Later, through a queue or a catch-up subscription.
  eventual,
}

/// What a provider needs to create an [EventBus].
final class EventBusConfig {
  /// Creates the config.
  const EventBusConfig({required this.consistency, this.transport});

  /// The consistency mode the bus serves.
  final ConsistencyMode consistency;

  /// Provider-specific transport name, such as a queue, for eventual
  /// consistency.
  final String? transport;
}
