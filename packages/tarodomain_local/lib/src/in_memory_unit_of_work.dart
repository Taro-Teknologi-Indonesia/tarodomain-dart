import 'dart:async';

import 'package:tarodomain/tarodomain.dart';

import 'local_database.dart';

/// A [UnitOfWork] over a [LocalDatabase] (spec §11.4).
///
/// It copies the tables on begin and puts the copy back if the work throws.
/// Units of work on one database run one at a time. Writes made outside any
/// unit of work while one is running are lost if it rolls back, so code that
/// shares a database with a unit of work should run inside one too.
final class InMemoryUnitOfWork implements UnitOfWork {
  /// Creates a unit of work over [database].
  InMemoryUnitOfWork(this.database);

  /// The database the work runs against.
  final LocalDatabase database;

  @override
  bool get isActive => Zone.current[database.unitOfWorkKey] == true;

  @override
  Future<T> execute<T>(Future<T> Function() work) async {
    if (isActive) return work();

    final previous = database.unitOfWorkQueue;
    final done = Completer<void>();
    database.unitOfWorkQueue = done.future;
    await previous;

    final backup = database.tables.copy();
    try {
      return await runZoned(work, zoneValues: {database.unitOfWorkKey: true});
    } catch (_) {
      database.tables = backup;
      rethrow;
    } finally {
      done.complete();
    }
  }
}
