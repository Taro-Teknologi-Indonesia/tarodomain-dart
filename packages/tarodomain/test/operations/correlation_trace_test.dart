import 'package:tarodomain/tarodomain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

/// The labels down a chain of only children, starting at [node].
List<String> chain(CausationTreeNode node) => [
  switch (node.kind) {
    CausationNodeKind.event => node.entry!.eventType,
    final kind => kind.name,
  },
  if (node.children case [final only]) ...chain(only),
];

/// An event with fixed tracing IDs.
SerializedEvent tracedEvent(
  UuidValue correlationId, {
  UuidValue? causationId,
  UuidValue? commandCausationId,
}) => DomainEvent.withEnvelope(
  EventEnvelope(
    id: MoneyDeposited(0).id,
    correlationId: correlationId,
    causationId: causationId,
    commandCausationId: commandCausationId,
    occurredAt: DateTime.utc(2026, 10, 12),
  ),
  () => MoneyDeposited(1),
).serialize();

void main() {
  for (final mode in ConsistencyMode.values) {
    test(
      'the transfer saga traces as one causation chain, ${mode.name}',
      () async {
        final h = TransferHarness(mode);
        await h.openWallets();
        final request = await h.requestTransfer(cents: 30, fee: 5);

        final entries = await CorrelationTrace.trace(
          h.eventStoreAdapter,
          request.correlationId,
        );
        final tree = CorrelationTrace.buildTree(entries);

        expect(tree.kind, CausationNodeKind.correlation);
        expect(tree.id, request.correlationId);
        expect(chain(tree), [
          'correlation',
          'command',
          'TransferRequested',
          'command',
          'MoneyWithdrawn',
          'command',
          'MoneyDeposited',
          'command',
          'FeeCharged',
          'command',
          'TransferCompleted',
        ]);

        final commandIds = <UuidValue>[];
        for (var n = tree; n.children.isNotEmpty; n = n.children.single) {
          if (n.kind == CausationNodeKind.command) commandIds.add(n.id);
        }
        expect(commandIds, [request.id, for (final c in h.sent) c.id]);
        expect(tree.events, hasLength(5));

        final text = CorrelationTrace.formatTree(tree);
        final lines = text.split('\n');
        expect(lines, hasLength(11));
        expect(lines.first, 'correlation ${request.correlationId.uuid}');
        expect(lines[1], '└─ command ${request.id.uuid}');
        expect(lines[2], startsWith('   └─ TransferRequested '));
      },
    );
  }

  group('buildTree', () {
    final correlationId = MoneyDeposited(0).id;

    List<CorrelationTraceEntry> entriesOf(List<SerializedEvent> events) => [
      for (final (i, e) in events.indexed) CorrelationTraceEntry(e, i),
    ];

    test('nests an event under the event that caused it', () {
      final root = tracedEvent(correlationId);
      final child = tracedEvent(correlationId, causationId: root.eventId);
      final sibling = tracedEvent(correlationId, causationId: root.eventId);

      final tree = CorrelationTrace.buildTree(
        entriesOf([root, child, sibling]),
      );

      final rootNode = tree.children.single;
      expect(rootNode.id, root.eventId);
      expect(
        [for (final c in rootNode.children) c.id],
        [child.eventId, sibling.eventId],
      );
      expect(CorrelationTrace.formatTree(tree).split('\n').skip(2).toList(), [
        startsWith('   ├─ MoneyDeposited'),
        startsWith('   └─ MoneyDeposited'),
      ]);
    });

    test('groups the events of one command', () {
      final command = MoneyDeposited(0).id;
      final a = tracedEvent(correlationId, causationId: command);
      final b = tracedEvent(correlationId, causationId: command);

      final tree = CorrelationTrace.buildTree(entriesOf([a, b]));

      final commandNode = tree.children.single;
      expect(commandNode.kind, CausationNodeKind.command);
      expect(commandNode.id, command);
      expect(commandNode.children, hasLength(2));
    });

    test('a command whose cause is outside the trace hangs off the root', () {
      final event = tracedEvent(
        correlationId,
        causationId: MoneyDeposited(0).id,
        commandCausationId: MoneyDeposited(0).id,
      );

      final tree = CorrelationTrace.buildTree(entriesOf([event]));

      expect(chain(tree), ['correlation', 'command', 'MoneyDeposited']);
    });

    test('an empty trace needs a correlation ID', () {
      expect(() => CorrelationTrace.buildTree([]), throwsArgumentError);
      final tree = CorrelationTrace.buildTree([], correlationId: correlationId);
      expect(tree.children, isEmpty);
      expect(CorrelationTrace.formatTree(tree), 'correlation $correlationId');
    });
  });

  group('commandCausationId', () {
    test('round-trips through JSON and is optional', () {
      final cause = MoneyDeposited(0).id;
      final event = tracedEvent(
        MoneyDeposited(0).id,
        causationId: MoneyDeposited(0).id,
        commandCausationId: cause,
      );

      final json = event.toJson();
      expect(json['commandCausationId'], cause.uuid);
      expect(SerializedEvent.fromJson(json), event);

      final withoutIt = Map.of(json)..remove('commandCausationId');
      expect(SerializedEvent.fromJson(withoutIt).commandCausationId, isNull);
    });

    test('a malformed value is an invalid causation ID', () {
      final json = tracedEvent(MoneyDeposited(0).id).toJson()
        ..['commandCausationId'] = 'nope';

      expect(
        () => SerializedEvent.fromJson(json),
        throwsA(isA<InvalidCausationIdError>()),
      );
    });

    test('events raised for a command carry its cause', () {
      final cause = MoneyDeposited(0).id;
      final command = CompleteTransfer(TransferId.generate());
      final event = ExecutionContext.run(
        ExecutionContext.forCommand(_CausedCommand(cause)),
        () => MoneyDeposited(1),
      );

      expect(event.commandCausationId, cause);
      expect(
        ExecutionContext.forCommand(command).commandCausationId,
        command.causationId,
      );
    });
  });
}

class _CausedCommand extends Command {
  _CausedCommand(UuidValue cause) : super(causationId: cause);
}
