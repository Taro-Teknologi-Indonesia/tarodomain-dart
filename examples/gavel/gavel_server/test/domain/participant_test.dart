import 'package:gavel_server/src/domain/gavel_domain.dart';
import 'package:gavel_server/src/domain/keys.dart';
import 'package:gavel_server/src/domain/participant.dart';
import 'package:gavel_server/src/domain/participant_commands.dart';
import 'package:tarodomain/tarodomain.dart';
import 'package:tarodomain_local/tarodomain_local.dart';
import 'package:test/test.dart';

void main() {
  late TaroDomain gavel;
  const key = 'participant-secret';
  final auctionId = AggregateId.generate().uuid;

  setUp(() {
    gavel = registerGavel(
      TaroDomain.builder().useLocal(),
    ).build().createRuntime();
  });

  JoinAuction join(String displayName, {ParticipantId? id}) => JoinAuction(
    id ?? ParticipantId.generate(),
    auctionId: auctionId,
    displayName: displayName,
    keyHash: hashKey(key),
  );

  Future<Participant> load(ParticipantId id) =>
      gavel.repository<Participant, ParticipantId>().load(id);

  Matcher invalidName(String reason) => isA<CommandValidationError>().having(
    (e) => e.context,
    'context',
    allOf([
      containsPair('field', 'displayName'),
      containsPair('reason', reason),
    ]),
  );

  group('the display name', () {
    test('empty is refused', () async {
      await expectLater(
        gavel.dispatch(join('   ')),
        throwsA(invalidName('EMPTY')),
      );
    });

    test('25 characters is too long', () async {
      await expectLater(
        gavel.dispatch(join('a' * 25)),
        throwsA(invalidName('TOO_LONG')),
      );
    });

    test('24 characters is accepted', () async {
      final command = join('a' * 24);
      await gavel.dispatch(command);

      expect((await load(command.participantId)).displayName, 'a' * 24);
    });

    test('an emoji is fine, and counts as one character', () async {
      final command = join('Budi 🙂${'a' * 18}');
      await gavel.dispatch(command);

      expect(
        (await load(command.participantId)).displayName,
        'Budi 🙂${'a' * 18}',
      );
    });

    test('a control character is refused', () async {
      await expectLater(
        gavel.dispatch(join('Bu\u0007di')),
        throwsA(invalidName('CONTROL_CHARACTER')),
      );
    });

    test('is trimmed', () async {
      final command = join('  Budi  ');
      await gavel.dispatch(command);

      expect((await load(command.participantId)).displayName, 'Budi');
    });
  });

  test('a joined participant keeps the auction and the key hash', () async {
    final command = join('Budi');
    await gavel.dispatch(command);

    final participant = await load(command.participantId);
    expect(participant.auctionId, auctionId);
    expect(participant.version, 1);
    expect(participant.hasKey(key), isTrue);
    expect(participant.hasKey('wrong'), isFalse);
  });

  test('ParticipantJoined leaves the key hash out', () {
    final participant = Participant.join(
      ParticipantId.generate(),
      auctionId: auctionId,
      displayName: 'Budi',
      keyHash: hashKey(key),
    );

    final event = participant.getUncommittedChanges().single;
    expect(event, isA<ParticipantJoined>());
    expect(event.toData().values, isNot(contains(hashKey(key))));
  });

  test('joining twice with the same ID is refused', () async {
    final id = ParticipantId.generate();
    await gavel.dispatch(join('Budi', id: id));

    await expectLater(
      gavel.dispatch(join('Mallory', id: id)),
      throwsA(isA<AggregateAlreadyExistsError>()),
    );
  });
}
