import 'package:gavel_client/gavel_client.dart';

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
  currentPrice: currentPrice ?? 150000,
  leaderId: leaderId,
  leaderName: leaderName,
  bidCount: leaderId == null ? 0 : 1,
  status: status,
  version: version,
  winnerName: winnerName,
);
