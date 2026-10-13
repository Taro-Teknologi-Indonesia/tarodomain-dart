import '../domain/domain_event.dart';
import 'event_bus.dart';

/// Receives events from an [EventBus] (spec §10.2), for example a projection
/// or a saga.
abstract interface class EventHandler {
  /// Unique name, used to prevent duplicate subscriptions and in errors.
  String get name;

  /// Handles [event]. Must be idempotent: the same event may be delivered
  /// more than once.
  Future<void> handle(DomainEvent event);
}

/// An [EventBus] that delivers events to handlers registered on it
/// (spec §10.4).
abstract interface class SubscribableEventBus implements EventBus {
  /// Registers [handler]. Subscribing the same handler twice does nothing.
  ///
  /// Throws `InvalidConfigurationError` if a different handler with the same
  /// name is already subscribed.
  void subscribe(EventHandler handler);

  /// Removes [handler]. Does nothing if it isn't subscribed.
  void unsubscribe(EventHandler handler);

  /// The subscribed handlers, in subscription order.
  List<EventHandler> get handlers;
}
