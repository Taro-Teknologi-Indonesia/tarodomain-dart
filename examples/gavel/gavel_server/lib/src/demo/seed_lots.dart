import '../generated/protocol.dart';

/// The default kelipatan ladder, in rupiah, as the lot form offers it.
const _ladder = [25000, 50000, 100000, 150000, 200000, 300000];

/// The lots of every demo auction (X2): four rings as a seller would post
/// them. Each [NewLot.imageUrl] is a path on the web server, the photos in
/// `gavel_flutter/web/lots`, made absolute when the demo is seeded; the
/// emoji tile shows where it isn't served.
final demoLots = [
  NewLot(
    name: 'Natural Pirus Hubei',
    openBid: 150000,
    increments: _ladder,
    buyNowPrice: null,
    description: '''
-----# LELANG #-----
Natural Pirus Hubei, cabochon oval
Ikat perak motif ukir
Warna biru toska, matrix spiderweb hitam
Kondisi mulus, siap pakai
OB: 150rb
KL: 25rb s/d 300rb
Pemenang transfer max 1x24 jam
-----# LELANG #-----''',
    imageUrl: 'lots/pirus-hubei.jpg',
    tileEmoji: '🔵',
    tileColor: '#2A8C82',
  ),
  NewLot(
    name: 'Blue Star Sapphire',
    openBid: 500000,
    increments: _ladder,
    buyNowPrice: null,
    description: '''
-----# LELANG #-----
Natural Blue Star Sapphire, cabochon oval
Ikat perak, kuku empat
Biru royal, bintang enam kaki tajam
Bintang jalan dengan senter
OB: 500rb
KL: 25rb s/d 300rb
Pemenang transfer max 1x24 jam
-----# LELANG #-----''',
    imageUrl: 'lots/blue-star-sapphire.jpg',
    tileEmoji: '⭐',
    tileColor: '#1E3F9A',
  ),
  NewLot(
    name: 'Ruby Star',
    openBid: 300000,
    increments: _ladder,
    buyNowPrice: null,
    description: '''
-----# LELANG #-----
Natural Ruby Star, cabochon oval
Ikat perak, kuku empat
Merah keunguan, kilau sutra
Natural apa adanya, ada guratan alami
OB: 300rb
KL: 25rb s/d 300rb
Pemenang transfer max 1x24 jam
-----# LELANG #-----''',
    imageUrl: 'lots/star-ruby.jpg',
    tileEmoji: '🔴',
    tileColor: '#7A1E4A',
  ),
  NewLot(
    name: 'Rhodonite Jumbo',
    openBid: 100000,
    increments: _ladder,
    buyNowPrice: null,
    description: '''
-----# LELANG #-----
Natural Rhodonite, cabochon oval jumbo
Ikat kuningan
Pink salem, urat putih alami
Kondisi mulus, siap pakai
OB: 100rb
KL: 25rb s/d 300rb
Pemenang transfer max 1x24 jam
-----# LELANG #-----''',
    imageUrl: 'lots/rhodonite.jpg',
    tileEmoji: '🌸',
    tileColor: '#C25B6E',
  ),
];
