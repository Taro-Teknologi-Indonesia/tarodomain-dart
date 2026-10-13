import 'package:uuid/uuid.dart';

import '../adapters/event_store_adapter.dart';
import '../domain/serialized_event.dart';

/// One event in a [CorrelationTrace].
final class CorrelationTraceEntry {
  /// Creates the entry for [event], the [position]th event of its trace.
  CorrelationTraceEntry(this.event, this.position);

  /// The event, as stored.
  final SerializedEvent event;

  /// Its position in the trace, in append order, from 0.
  final int position;

  /// The event ID.
  UuidValue get eventId => event.eventId;

  /// The event type.
  String get eventType => event.eventType;

  /// The command or event that caused it.
  UuidValue? get causationId => event.causationId;

  /// The cause of the command that raised it.
  UuidValue? get commandCausationId => event.commandCausationId;

  /// When it was raised, in UTC.
  DateTime get occurredAt => event.occurredAt;

  @override
  String toString() => 'CorrelationTraceEntry($eventType $eventId)';
}

/// The kinds of node in a causation tree.
enum CausationNodeKind {
  /// The root: the correlation ID shared by the whole trace.
  correlation,

  /// A command, known only by its ID, since commands aren't stored.
  command,

  /// A stored event.
  event,
}

/// A node of the tree built by [CorrelationTrace.buildTree].
final class CausationTreeNode {
  CausationTreeNode._(this.kind, this.id, [this.entry]);

  /// What the node stands for.
  final CausationNodeKind kind;

  /// The correlation, command or event ID.
  final UuidValue id;

  /// The event, for an [CausationNodeKind.event] node.
  final CorrelationTraceEntry? entry;

  final _children = <CausationTreeNode>[];

  /// What this node caused, in the order they were stored.
  List<CausationTreeNode> get children => List.unmodifiable(_children);

  /// The position used to order siblings: the event's, or for a command the
  /// first event it raised.
  int get _position => entry?.position ?? _children.firstOrNull?._position ?? 0;

  /// Every event below this node, depth first.
  Iterable<CorrelationTraceEntry> get events sync* {
    if (entry case final entry?) yield entry;
    for (final child in _children) {
      yield* child.events;
    }
  }

  @override
  String toString() => 'CausationTreeNode(${kind.name} $id)';
}

/// Debugging help that shows what caused what within one correlation ID
/// (spec §28.3).
///
/// Events record the command that raised them as their cause, and that
/// command's own cause in `commandCausationId`. Commands aren't stored, so
/// the tree has a node for each command inferred from its events, placed
/// under the event that caused it:
///
/// ```text
/// correlation 0199…
/// └─ command 0199…
///    └─ TransferRequested 0199… at 2026-10-12T09:00:00.000Z
///       └─ command 0199…
///          └─ MoneyWithdrawn 0199… at 2026-10-12T09:00:00.004Z
/// ```
abstract final class CorrelationTrace {
  /// Every event with [correlationId], in append order.
  static Future<List<CorrelationTraceEntry>> trace(
    EventStoreAdapter eventStore,
    UuidValue correlationId,
  ) async => [
    for (final (i, event) in (await eventStore.loadByCorrelationId(
      correlationId,
    )).indexed)
      CorrelationTraceEntry(event, i),
  ];

  /// The causation tree of [entries], under a root for [correlationId], by
  /// default the correlation ID of the first entry.
  ///
  /// An event goes under the event that caused it, or under the node of the
  /// command that raised it. A command goes under the event that caused it,
  /// or under the root when that event isn't in [entries], as for a command
  /// from outside the system.
  ///
  /// Throws [ArgumentError] if [entries] is empty and no [correlationId] is
  /// given.
  static CausationTreeNode buildTree(
    List<CorrelationTraceEntry> entries, {
    UuidValue? correlationId,
  }) {
    final rootId =
        correlationId ??
        (entries.isEmpty
            ? throw ArgumentError.value(
                entries,
                'entries',
                'is empty and no correlationId was given',
              )
            : entries.first.event.correlationId);
    final root = CausationTreeNode._(CausationNodeKind.correlation, rootId);
    final events = {
      for (final entry in entries)
        entry.eventId: CausationTreeNode._(
          CausationNodeKind.event,
          entry.eventId,
          entry,
        ),
    };
    final commands = <UuidValue, CausationTreeNode>{};
    final commandParents = <UuidValue, UuidValue?>{};
    final parents = <CausationTreeNode, CausationTreeNode>{};

    for (final entry in entries) {
      final node = events[entry.eventId]!;
      final cause = entry.causationId;
      if (cause == null) {
        parents[node] = root;
      } else if (events[cause] case final causeEvent?) {
        parents[node] = causeEvent;
      } else {
        parents[node] = commands.putIfAbsent(
          cause,
          () => CausationTreeNode._(CausationNodeKind.command, cause),
        );
        commandParents[cause] ??= entry.commandCausationId;
      }
    }
    for (final MapEntry(key: id, value: command) in commands.entries) {
      parents[command] = events[commandParents[id]] ?? root;
    }

    for (final MapEntry(key: node, value: parent) in parents.entries) {
      (_reachesRoot(node, parents, root) ? parent : root)._children.add(node);
    }
    _sort(root);
    return root;
  }

  /// [tree] as indented text, one node per line.
  static String formatTree(CausationTreeNode tree) {
    final lines = [_label(tree)];
    void walk(CausationTreeNode node, String indent) {
      final children = node._children;
      for (final (i, child) in children.indexed) {
        final last = i == children.length - 1;
        lines.add('$indent${last ? '└─ ' : '├─ '}${_label(child)}');
        walk(child, '$indent${last ? '   ' : '│  '}');
      }
    }

    walk(tree, '');
    return lines.join('\n');
  }

  static String _label(CausationTreeNode node) => switch (node.kind) {
    CausationNodeKind.correlation => 'correlation ${node.id.uuid}',
    CausationNodeKind.command => 'command ${node.id.uuid}',
    CausationNodeKind.event =>
      '${node.entry!.eventType} ${node.id.uuid} at '
          '${node.entry!.occurredAt.toIso8601String()}',
  };

  /// Whether following [parents] up from [node] reaches [root] rather than
  /// going round a cycle, which malformed causation IDs could create.
  static bool _reachesRoot(
    CausationTreeNode node,
    Map<CausationTreeNode, CausationTreeNode> parents,
    CausationTreeNode root,
  ) {
    final seen = <CausationTreeNode>{};
    for (CausationTreeNode? n = node; n != null; n = parents[n]) {
      if (identical(n, root)) return true;
      if (!seen.add(n)) return false;
    }
    return false;
  }

  static void _sort(CausationTreeNode node) {
    for (final child in node._children) {
      _sort(child);
    }
    node._children.sort((a, b) => a._position.compareTo(b._position));
  }
}
