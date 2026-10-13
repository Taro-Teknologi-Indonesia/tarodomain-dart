import 'package:gavel_client/gavel_client.dart';

/// [name] as two names compare: trimmed and case-insensitive.
String _normalize(String name) => name.trim().toLowerCase();

/// The names, normalized, that more than one participant goes by among
/// [people]: the bidders whose name needs its tag (UC-09).
Set<String> sharedNames(Iterable<(String name, UuidValue id)> people) {
  final ids = <String, Set<UuidValue>>{};
  for (final (name, id) in people) {
    (ids[_normalize(name)] ??= {}).add(id);
  }
  return {
    for (final MapEntry(:key, :value) in ids.entries)
      if (value.length > 1) key,
  };
}

/// [name] with [id]'s tag, as `Budi · #3f9c`.
String tagged(String name, UuidValue id) => '$name · ${nameTag(id)}';

/// [name], tagged only when someone else in [shared] goes by it too, so
/// the common case looks unchanged.
String displayName(String name, UuidValue? id, Set<String> shared) =>
    id != null && shared.contains(_normalize(name)) ? tagged(name, id) : name;
