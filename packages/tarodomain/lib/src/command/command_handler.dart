import 'package:meta/meta.dart';

import '../domain/aggregate_root.dart';
import '../bus/event_bus.dart';
import '../domain/aggregate_id.dart';
import '../domain/command.dart';
import '../domain/domain_event.dart';
import '../errors/error_codes.dart';
import '../repository/repository.dart';

/// Executes commands of type [C] (spec §4.1).
///
/// Handlers validate the command, throw a domain error on a violation, and
/// otherwise load, change and save aggregates. Most handlers work on one
/// aggregate and extend [AggregateCommandHandler]; extend this class
/// directly for handlers that don't.
///
/// A handler may be run more than once for one command, because the
/// pipeline retries it after a concurrency conflict. It must therefore load
/// everything it needs inside [handle].
abstract class CommandHandler<C extends Command> {
  /// Executes [command].
  Future<void> handle(C command);
}

/// A [CommandHandler] for commands on one aggregate type [A], with helpers
/// that delegate to its [repository] (spec §4.1).
///
/// ```dart
/// class DepositHandler
///     extends AggregateCommandHandler<Deposit, BankAccount, AccountId> {
///   DepositHandler(super.repository);
///
///   @override
///   Future<void> handle(Deposit command) async {
///     final account = await load(command.accountId);
///     account.deposit(command.cents);
///     await save(account);
///   }
/// }
/// ```
abstract class AggregateCommandHandler<
  C extends Command,
  A extends AggregateRoot<TId, DomainEvent>,
  TId extends AggregateId
>
    extends CommandHandler<C> {
  /// Creates the handler over [repository].
  AggregateCommandHandler(this.repository);

  /// Loads and saves the aggregates.
  final Repository<A, TId> repository;

  /// Loads the aggregate with [id].
  ///
  /// Throws [AggregateNotFoundError] if it doesn't exist.
  @protected
  Future<A> load(TId id) => repository.load(id);

  /// Loads the aggregate with [id], or returns null if it doesn't exist.
  @protected
  Future<A?> loadOrNull(TId id) async =>
      await repository.exists(id) ? await repository.load(id) : null;

  /// Saves [aggregate] and publishes its new events.
  @protected
  Future<void> save(A aggregate) => repository.save(aggregate);

  /// Whether the aggregate with [id] exists.
  @protected
  Future<bool> exists(TId id) => repository.exists(id);
}

/// What a pipeline gives a [CommandHandlerFactory] when it creates a
/// handler.
///
/// Each pipeline has its own event bus (spec §11.3), so a handler's
/// repositories must be built with [eventBus] for its events to reach the
/// right handlers.
final class CommandHandlerContext {
  /// Creates the context.
  const CommandHandlerContext({
    required this.consistency,
    required this.eventBus,
  });

  /// The consistency mode of the pipeline running the handler.
  final ConsistencyMode consistency;

  /// The pipeline's event bus, for the handler's repositories.
  final EventBus eventBus;
}

/// Creates the handler for a command, for the pipeline described by
/// `context`.
typedef CommandHandlerFactory<C extends Command> =
    CommandHandler<C> Function(CommandHandlerContext context);
