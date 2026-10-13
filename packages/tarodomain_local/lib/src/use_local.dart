import 'package:tarodomain/tarodomain.dart';

import 'local_database.dart';
import 'local_provider.dart';

/// Adds `useLocal()` to the builder (spec §25.1).
extension UseLocalProvider on TaroDomainBuilder {
  /// Uses a [LocalProvider] over [database], or over a new empty one, for
  /// runtimes created without a provider. Every such runtime shares it.
  TaroDomainBuilder useLocal({LocalDatabase? database}) =>
      useProvider(LocalProvider(database: database));
}
