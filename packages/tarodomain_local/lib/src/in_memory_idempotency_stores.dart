import 'package:tarodomain/tarodomain.dart';

import 'local_database.dart';

/// A [ProcessedEventStore] over a [LocalDatabase].
final class InMemoryProcessedEventStore implements ProcessedEventStore {
  /// Creates the store.
  InMemoryProcessedEventStore(this.database);

  /// The database the records live in.
  final LocalDatabase database;

  Map<(String, String, String), DateTime> get _records =>
      database.tables.processedEvents;

  @override
  Future<bool> exists(
    String handlerName,
    String handlerInstance,
    UuidValue eventId,
  ) async => _records.containsKey((handlerName, handlerInstance, eventId.uuid));

  @override
  Future<void> markProcessed(
    String handlerName,
    String handlerInstance,
    UuidValue eventId,
  ) async {
    _records.putIfAbsent((
      handlerName,
      handlerInstance,
      eventId.uuid,
    ), database.now);
  }

  @override
  Future<int> count(String handlerName, {String? handlerInstance}) async =>
      _records.keys.where(_matches(handlerName, handlerInstance)).length;

  @override
  Future<int> deleteByHandler(
    String handlerName, {
    String? handlerInstance,
  }) async {
    final matches = _matches(handlerName, handlerInstance);
    final before = _records.length;
    _records.removeWhere((key, _) => matches(key));
    return before - _records.length;
  }

  @override
  Future<int> deleteOld(DateTime olderThan) async {
    final before = _records.length;
    _records.removeWhere((_, at) => at.isBefore(olderThan));
    return before - _records.length;
  }

  static bool Function((String, String, String)) _matches(
    String handlerName,
    String? handlerInstance,
  ) =>
      (key) =>
          key.$1 == handlerName &&
          (handlerInstance == null || key.$2 == handlerInstance);
}

/// A [CommandIdempotencyStore] over a [LocalDatabase].
final class InMemoryCommandIdempotencyStore implements CommandIdempotencyStore {
  /// Creates the store.
  InMemoryCommandIdempotencyStore(this.database);

  /// The database the records live in.
  final LocalDatabase database;

  Map<String, ProcessedCommand> get _records =>
      database.tables.processedCommands;

  @override
  Future<bool> exists(UuidValue commandId) async =>
      _records.containsKey(commandId.uuid);

  @override
  Future<void> markProcessed(
    UuidValue commandId,
    String commandType,
    String handlerName,
  ) async {
    _records.putIfAbsent(
      commandId.uuid,
      () => ProcessedCommand(
        commandId: commandId,
        commandType: commandType,
        handlerName: handlerName,
        processedAt: database.now(),
      ),
    );
  }

  @override
  Future<DateTime?> getProcessedAt(UuidValue commandId) async =>
      _records[commandId.uuid]?.processedAt;

  @override
  Future<int> count({String? handlerName}) async => _records.values
      .where((c) => handlerName == null || c.handlerName == handlerName)
      .length;

  @override
  Future<List<ProcessedCommand>> list(String handlerName, {int? limit}) async =>
      sortedByTime(
        _records.values.where((c) => c.handlerName == handlerName),
        (c) => c.processedAt,
        newestFirst: true,
        limit: limit,
      );

  @override
  Future<int> deleteOld(DateTime olderThan) async {
    final before = _records.length;
    _records.removeWhere((_, c) => c.processedAt.isBefore(olderThan));
    return before - _records.length;
  }
}
