import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

final _thousands = NumberFormat.decimalPattern('id_ID');

/// [amount] in rupiah, as `Rp 250.000`.
String formatRupiah(int amount) => _rupiah.format(amount);

/// [amount] with Indonesian thousands separators, as `250.000`.
String formatThousands(int amount) => _thousands.format(amount);

/// A kelipatan step, as `+25k`, or in full when it isn't whole thousands.
String formatStep(int amount) =>
    amount % 1000 == 0 ? '+${amount ~/ 1000}k' : '+${formatRupiah(amount)}';
