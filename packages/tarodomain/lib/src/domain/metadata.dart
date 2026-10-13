import 'package:meta/meta.dart';

/// Returns an unmodifiable copy of [metadata] after checking that every value
/// is a primitive (spec §2.1: `Map<string, primitive>`).
@internal
Map<String, Object?> freezeMetadata(Map<String, Object?> metadata) {
  for (final MapEntry(:key, :value) in metadata.entries) {
    if (value != null && value is! String && value is! num && value is! bool) {
      throw ArgumentError.value(
        metadata,
        'metadata',
        'Value for "$key" must be a String, num, bool or null, '
            'not ${value.runtimeType}',
      );
    }
  }
  return Map.unmodifiable(metadata);
}
