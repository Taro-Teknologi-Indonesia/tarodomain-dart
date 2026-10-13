import 'dart:async';
import 'dart:collection';

import 'package:uuid/uuid.dart';

import '../adapters/idempotency_stores.dart';
import '../adapters/saga_store_adapter.dart';
import '../bus/event_handler.dart';
import '../domain/command.dart';
import '../domain/domain_event.dart';
import 'process_manager.dart';

/// Dispatches one command for a saga. Usually `dispatcher.dispatch`; a
/// rebuild passes one that discards the command.
typedef SagaCommandDispatch = Future<void> Function(Command command);

/// Runs a [ProcessManager] type as an [EventHandler] (spec §13.3).
///
/// For each event it:
///
/// 1. skips the event if this saga instance already handled it;
/// 2. loads the saga whose ID is the event's correlation ID, or creates one
///    if the event starts the saga, and otherwise skips the event;
/// 3. skips the event, recording it as handled, if the saga is already
///    completed or failed;
/// 4. skips the event if the saga has no handler for it, without saving the
///    saga, so that unrelated events don't delay its timeout;
/// 5. runs the saga's handler and dispatches the commands it returns, in
///    order;
/// 6. saves the saga, which sets `completedAt` once it is terminal;
/// 7. records the event as handled.
///
/// Commands are dispatched before the saga is saved: if a dispatch fails,
/// nothing is saved, and the event is retried from the old state.
///
/// A command the saga dispatches can publish an event for the same saga
/// before the saga is saved, when the event bus delivers in the caller's
/// zone, as under strong consistency. That event waits until the current one
/// is finished and the saga saved, and is then handled in the same call, so
/// each saga sees its events one at a time and in order.
final class SagaEventHandler implements EventHandler {
  /// Creates the handler for the sagas [create] makes. [create] must return
  /// a new, unstarted saga each time.
  SagaEventHandler({
    required ProcessManager<Object?> Function() create,
    required this.sagaStore,
    required this.processedEvents,
    required this.dispatch,
  }) : _create = create,
       _prototype = create();

  final ProcessManager<Object?> Function() _create;

  /// An unstarted instance, used for routing.
  final ProcessManager<Object?> _prototype;

  /// Stores saga state.
  final SagaStoreAdapter sagaStore;

  /// Records which events each saga instance handled.
  final ProcessedEventStore processedEvents;

  /// Dispatches the commands the saga returns.
  final SagaCommandDispatch dispatch;

  final Object _mailboxesKey = Object();

  /// The saga type.
  String get sagaType => _prototype.sagaType;

  @override
  String get name => sagaType;

  /// Whether [event] would start a saga of this type.
  bool canStart(DomainEvent event) => _prototype.canStart(event);

  /// Whether a saga of this type has a handler for [event].
  bool handles(DomainEvent event) => _prototype.routeFor(event) != null;

  @override
  Future<void> handle(DomainEvent event) async {
    final active =
        Zone.current[_mailboxesKey] as Map<UuidValue, Queue<DomainEvent>>?;
    if (active?[event.correlationId] case final mailbox?) {
      mailbox.add(event);
      return;
    }
    final mailbox = Queue.of([event]);
    await runZoned(
      () async {
        while (mailbox.isNotEmpty) {
          await _process(mailbox.removeFirst());
        }
      },
      zoneValues: {
        _mailboxesKey: {...?active, event.correlationId: mailbox},
      },
    );
  }

  Future<void> _process(DomainEvent event) async {
    final sagaId = event.correlationId;
    final instance = sagaId.uuid;
    if (await processedEvents.exists(sagaType, instance, event.id)) return;

    final record = await sagaStore.load(sagaType, sagaId);
    final ProcessManager<Object?> saga;
    if (record != null) {
      saga = _create()..restore(record);
    } else if (canStart(event)) {
      saga = _create();
    } else {
      return;
    }

    if (saga.isTerminal) {
      await processedEvents.markProcessed(sagaType, instance, event.id);
      return;
    }
    // Saving would move `updatedAt`, and with it the saga's timeout.
    if (saga.routeFor(event) == null) return;

    for (final command in saga.handle(event)) {
      await dispatch(command);
    }
    await sagaStore.save(saga.toSaveInput());
    await processedEvents.markProcessed(sagaType, instance, event.id);
  }
}
