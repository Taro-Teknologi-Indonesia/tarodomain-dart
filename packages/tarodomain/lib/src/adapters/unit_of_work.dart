/// Runs a block of storage work atomically (spec §11.4).
///
/// The spec's `begin`/`commit`/`rollback` become a single [execute], because
/// Serverpod only offers callback-style transactions. Adapters created by the
/// same provider join the active unit of work on their own.
abstract interface class UnitOfWork {
  /// Whether [execute] is running in the current zone.
  bool get isActive;

  /// Runs [work] and commits its writes if it completes, or discards them if
  /// it throws, then rethrows.
  ///
  /// Calling [execute] while one is already active runs [work] inside the
  /// outer unit of work, which alone commits or rolls back.
  Future<T> execute<T>(Future<T> Function() work);
}
