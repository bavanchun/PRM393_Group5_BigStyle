import 'package:intl/intl.dart';

final NumberFormat _vndGrouping = NumberFormat('#,###', 'vi_VN');

/// App-wide VND display format: whole-đồng amounts with dot grouping,
/// no space before the đ suffix (e.g. 350000 → "350.000đ").
String formatVnd(num amount) => '${_vndGrouping.format(amount)}đ';
