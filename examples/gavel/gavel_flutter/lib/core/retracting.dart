import 'package:gavel_client/gavel_client.dart';

import 'identity.dart';

/// Takes back a bid: `LotEndpoint.retractBid`, or a fake in tests.
typedef SendRetract =
    Future<LotCard> Function({
      required UuidValue lotId,
      required Identity identity,
      required int expectedVersion,
      required UuidValue commandId,
    });

/// [SendRetract] through [client].
SendRetract sendRetractWith(Client client) =>
    ({
      required lotId,
      required identity,
      required expectedVersion,
      required commandId,
    }) => client.lot.retractBid(
      lotId,
      identity.participantId,
      identity.participantKey,
      expectedVersion,
      commandId,
    );
