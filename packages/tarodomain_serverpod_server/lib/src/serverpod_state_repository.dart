import 'package:meta/meta.dart';
import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';

import 'db/taro_db.dart';
import 'serverpod_provider.dart';

/// A state repository (spec §6.3, §15.4) that keeps an aggregate's current
/// state in a table of the app's own, through Serverpod's ORM.
///
/// [R] is the app's row model. Its table needs a `UuidValue` ID, which
/// holds the aggregate ID, and an `int` column named `version`. A subclass
/// provides only [toRow] and [fromRow]:
///
/// ```dart
/// class ExpenseRepository
///     extends ServerpodStateRepository<ExpenseAggregate, ExpenseId, Expense> {
///   ExpenseRepository(super.context);
///
///   @override
///   Expense toRow(ExpenseAggregate a) => Expense(
///     id: a.id.value, amount: a.amount, version: a.version);
///
///   @override
///   ExpenseAggregate fromRow(Expense row) => ExpenseAggregate.fromRow(row);
/// }
/// ```
///
/// Saving checks optimistic concurrency with the version column, writes the
/// row, and appends the aggregate's new events to its stream, in one
/// transaction (the unit of work's, if one is active). Storing the events
/// lets catch-up deliver them to projections and sagas under eventual
/// consistency, where the bus only schedules catch-up, and keeps them in
/// correlation traces. The stream's version therefore follows the row's.
abstract class ServerpodStateRepository<
  A extends AggregateRoot<TId, DomainEvent>,
  TId extends AggregateId,
  R extends TableRow<UuidValue?>
>
    extends StateRepository<A, TId> {
  /// Creates the repository for a runtime on a [ServerpodProvider], for the
  /// aggregate type registered for [A].
  ///
  /// Throws [InvalidConfigurationError] if the runtime's provider is
  /// another kind.
  ServerpodStateRepository(RepositoryContext context)
    : this.withSession(
        _sessionOf(context.provider),
        aggregateType:
            context.framework.definition.aggregateFor<A>()?.aggregateType ??
            '$A',
        eventStore: context.eventStore,
        eventBus: context.eventBus,
      );

  /// Creates the repository on [session] directly.
  ServerpodStateRepository.withSession(
    Session session, {
    required this.aggregateType,
    required this.eventStore,
    required EventBus eventBus,
  }) : _db = TaroDb(session),
       super(eventBus);

  /// The aggregate type name, used in stream IDs.
  final String aggregateType;

  /// Where the aggregate's events are appended.
  final EventStore eventStore;

  final TaroDb _db;

  /// The request's session.
  Session get session => _db.session;

  /// The row model's table. Defaults to the table Serverpod registered for
  /// [R].
  Table<Object?> get table =>
      _db.tableFor(R) ??
      (throw InvalidConfigurationError(
        '$R is not a Serverpod table row',
        context: {'row': '$R'},
      ));

  /// The row model's version column. Defaults to the column named
  /// `version`.
  ColumnInt get versionColumn =>
      table.columns.whereType<ColumnInt>().firstWhere(
        (c) => c.columnName == 'version',
        orElse: () => throw InvalidConfigurationError(
          '$R has no int column named version',
          context: {'row': '$R'},
        ),
      );

  /// The row that stores [aggregate]'s current state. Its ID must be
  /// `aggregate.id.value` and its version `aggregate.version`.
  @protected
  R toRow(A aggregate);

  /// The aggregate stored in [row], at the row's version (see
  /// [AggregateRoot.restoreVersion]).
  @protected
  A fromRow(R row);

  /// The ID of the aggregate's stream.
  String streamIdFor(TId id) => StreamIds.forAggregate(aggregateType, id);

  @override
  Future<A> load(TId id) async {
    final row = await _db.findFirstRow<R>(where: table.id.equals(id.value));
    if (row == null) {
      throw AggregateNotFoundError(
        '$aggregateType ${id.uuid} not found',
        context: {'aggregateType': aggregateType, 'aggregateId': id.uuid},
      );
    }
    return fromRow(row);
  }

  @override
  Future<bool> exists(TId id) async =>
      await _db.count<R>(where: table.id.equals(id.value)) > 0;

  @override
  @protected
  Future<void> saveState(A aggregate) => _db.atomically(() async {
    final expected = aggregate.committedVersion;
    final List<R> written;
    if (expected == 0) {
      written = await _db.insert<R>([toRow(aggregate)], ignoreConflicts: true);
    } else {
      final version = versionColumn;
      written = await _db.updateWhere<R>(
        columnValues: [ColumnValue(version, aggregate.version)],
        where: table.id.equals(aggregate.id.value) & version.equals(expected),
      );
      if (written.isNotEmpty) await _db.updateRow<R>(toRow(aggregate));
    }
    if (written.isEmpty) {
      throw OptimisticConcurrencyError(
        '$aggregateType ${aggregate.id.uuid} changed since it was loaded',
        context: {
          'aggregateType': aggregateType,
          'aggregateId': aggregate.id.uuid,
          'expectedVersion': expected,
        },
      );
    }
    await eventStore.appendToStream(
      streamIdFor(aggregate.id),
      aggregate.getUncommittedChanges(),
      expected,
    );
  });

  static Session _sessionOf(Provider provider) => switch (provider) {
    ServerpodProvider(:final session) => session,
    _ => throw InvalidConfigurationError(
      'ServerpodStateRepository needs a ServerpodProvider, '
      'not "${provider.type}"',
      context: {'provider': provider.type},
    ),
  };
}
