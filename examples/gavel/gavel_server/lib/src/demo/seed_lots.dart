import '../generated/protocol.dart';

/// The default kelipatan ladder, in rupiah, as the lot form offers it.
const _ladder = [25000, 50000, 100000, 150000, 200000, 300000];

/// The lots of every demo auction (X2): three stones as a seller would post
/// them, with emoji tiles rather than photos, so no link can break.
final demoLots = [
  NewLot(
    name: 'Natural Pirus Hubei',
    openBid: 150000,
    increments: _ladder,
    buyNowPrice: null,
    description: '''
-----# LELANG #-----
Natural Pirus Hubei, cabochon oval
Ukuran: 18 x 13 mm
Berat: 12,4 ct
Warna biru langit, matrix tipis
OB: 150rb
KL: 25rb s/d 300rb
Pemenang transfer max 1x24 jam
-----# LELANG #-----''',
    imageUrl: null,
    tileEmoji: '🔵',
    tileColor: '#1E5AA8',
  ),
  NewLot(
    name: 'Bacan Doko Kristal',
    openBid: 250000,
    increments: _ladder,
    buyNowPrice: null,
    description: '''
-----# LELANG #-----
Bacan Doko asli Halmahera, sudah kristal
Ukuran: 14 x 11 mm
Berat: 7,8 ct
Hijau tua, tembus senter
OB: 250rb
KL: 25rb s/d 300rb
Pemenang transfer max 1x24 jam
-----# LELANG #-----''',
    imageUrl: null,
    tileEmoji: '🟢',
    tileColor: '#2E7D6B',
  ),
  NewLot(
    name: 'Kecubung Ungu Kalimantan',
    openBid: 100000,
    increments: _ladder,
    buyNowPrice: null,
    description: '''
-----# LELANG #-----
Kecubung Ungu Kalimantan, potong faset
Ukuran: 16 x 12 mm
Berat: 9,1 ct
Ungu rata, bersih tanpa retak
OB: 100rb
KL: 25rb s/d 300rb
Pemenang transfer max 1x24 jam
-----# LELANG #-----''',
    imageUrl: null,
    tileEmoji: '🔮',
    tileColor: '#6B4FA0',
  ),
];
