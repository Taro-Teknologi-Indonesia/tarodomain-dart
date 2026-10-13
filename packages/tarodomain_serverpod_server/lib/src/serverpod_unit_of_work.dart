import 'dart:async';

import 'package:meta/meta.dart';
import 'package:serverpod/serverpod.dart';
import 'package:tarodomain/tarodomain.dart';

/// A [UnitOfWork] on a Serverpod transaction (spec §11.4).
///
/// [execute] runs its work in `session.db.transaction` and keeps the
/// transaction in a zone value. Serverpod's ORM doesn't pick up an ambient
/// transaction by itself, so every store of this package reads it with
/// [transactionOf] and passes it on. Units of work on the same [session]
/// share the transaction, whichever provider created them.
final class ServerpodUnitOfWork implements UnitOfWork {
  /// Creates a unit of work on [session].
  ServerpodUnitOfWork(this.session);

  /// The session whose database the work runs against.
  final Session session;

  static final Object _key = Object();

  @override
  bool get isActive => _active(session) != null;

  @override
  Future<T> execute<T>(Future<T> Function() work) async {
    if (isActive) return work();
    return separately(session, work);
  }

  /// Runs [work] in a new transaction on [session], even if a unit of work
  /// is already active, and commits it when [work] completes. For work that
  /// must not join the caller's transaction, such as assigning event
  /// positions.
  @internal
  static Future<T> separately<T>(
    Session session,
    Future<T> Function() work,
  ) async {
    final afterCommit = <Future<void> Function()>[];
    final result = await session.db.transaction(
      (transaction) => _run(session, transaction, afterCommit, work),
    );
    for (final callback in afterCommit) {
      try {
        await callback();
      } catch (e, stackTrace) {
        session.log(
          'TaroDomain after-commit callback failed: $e',
          level: LogLevel.error,
          exception: e,
          stackTrace: stackTrace,
        );
      }
    }
    return result;
  }

  /// Runs [work] in [transaction], an existing Serverpod transaction on
  /// [session], so the stores join it: for an endpoint that opened its own
  /// transaction and dispatches commands inside it.
  ///
  /// The caller commits or rolls back [transaction]. Callbacks registered
  /// with [afterCommit] run when [work] completes.
  static Future<T> join<T>(
    Session session,
    Transaction transaction,
    Future<T> Function() work,
  ) async {
    final afterCommit = <Future<void> Function()>[];
    final result = await _run(session, transaction, afterCommit, work);
    for (final callback in afterCommit) {
      await callback();
    }
    return result;
  }

  /// The transaction of the unit of work active on [session] in the current
  /// zone, or null.
  static Transaction? transactionOf(Session session) =>
      _active(session)?.transaction;

  /// Runs [callback] once the unit of work active on [session] commits, or
  /// at once if none is active. Nothing runs if it rolls back.
  ///
  /// A callback that throws is logged and doesn't affect the others.
  static Future<void> afterCommit(
    Session session,
    Future<void> Function() callback,
  ) async {
    final active = _active(session);
    if (active == null) return callback();
    active.afterCommit.add(callback);
  }

  static Future<T> _run<T>(
    Session session,
    Transaction transaction,
    List<Future<void> Function()> afterCommit,
    Future<T> Function() work,
  ) => runZoned(
    work,
    zoneValues: {
      _key: {
        ...?Zone.current[_key] as Map<Session, _ActiveTransaction>?,
        session: _ActiveTransaction(transaction, afterCommit),
      },
    },
  );

  static _ActiveTransaction? _active(Session session) =>
      (Zone.current[_key] as Map<Session, _ActiveTransaction>?)?[session];
}

final class _ActiveTransaction {
  _ActiveTransaction(this.transaction, this.afterCommit);

  final Transaction transaction;
  final List<Future<void> Function()> afterCommit;
}
