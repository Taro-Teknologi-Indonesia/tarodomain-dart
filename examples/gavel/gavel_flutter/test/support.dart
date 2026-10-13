import 'dart:convert';

import 'package:gavel_client/gavel_client.dart';
import 'package:tarodomain_serverpod_client/tarodomain_serverpod_client.dart';

final lotId = UuidValue.fromString('00000000-0000-4000-8000-000000000001');
final budi = UuidValue.fromString('00000000-0000-4000-8000-0000000000b1');
final siti = UuidValue.fromString('00000000-0000-4000-8000-0000000000c1');

/// An open lot with no bids, opening at Rp 150.000.
LotCard lotCard({
  int version = 1,
  int? currentPrice,
  String status = 'OPEN',
  String? imageUrl,
  UuidValue? leaderId,
  String? leaderName,
  String? winnerName,
  int? finalPrice,
  int? buyNowPrice,
  String? closeCause,
  DateTime? closedAt,
}) => LotCard(
  lotId: lotId,
  auctionId: UuidValue.fromString('00000000-0000-4000-8000-0000000000a1'),
  code: 'ABC234',
  position: 0,
  name: 'Batik tulis Lasem',
  description: 'Hand-drawn, 2 m.',
  imageUrl: imageUrl,
  tileEmoji: '🧵',
  tileColor: '#8D5524',
  openBid: 150000,
  increments: const [25000, 50000],
  buyNowPrice: buyNowPrice,
  currentPrice: currentPrice ?? 150000,
  leaderId: leaderId,
  leaderName: leaderName,
  bidCount: leaderId == null ? 0 : 1,
  status: status,
  version: version,
  winnerName: winnerName,
  finalPrice: finalPrice,
  closeCause: closeCause,
  closedAt: closedAt,
);

/// The exception the server sends for a domain error [code] with
/// [context].
TaroDomainException domainError(String code, [Map<String, Object?>? context]) =>
    TaroDomainException(
      code: code,
      category: 'DOMAIN',
      retryable: false,
      httpStatus: 409,
      message: code,
      context: context == null ? null : jsonEncode(context),
    );

/// Bid [sequence] on the lot, placed at 22:01:00 UTC plus [sequence]
/// seconds.
LedgerEntry ledgerEntry(
  int sequence, {
  UuidValue? by,
  String name = 'Budi',
  int? amount,
  bool retracted = false,
}) => LedgerEntry(
  lotId: lotId,
  sequence: sequence,
  participantId: by ?? budi,
  bidderName: name,
  amount: amount ?? 150000 + 25000 * sequence,
  placedAt: DateTime.utc(2026, 10, 14, 22, 1, sequence),
  retracted: retracted,
  retractedAt: retracted
      ? DateTime.utc(2026, 10, 14, 22, 1, sequence + 5)
      : null,
);
