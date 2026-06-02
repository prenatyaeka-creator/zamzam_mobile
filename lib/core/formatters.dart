import 'package:intl/intl.dart';

final NumberFormat _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String formatCurrency(num value) => _currency.format(value);
String formatDateTime(DateTime value) => DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(value);
String formatShortDate(DateTime value) => DateFormat('dd MMM yyyy', 'id_ID').format(value);
String formatShortTime(DateTime value) => DateFormat('HH:mm', 'id_ID').format(value);
