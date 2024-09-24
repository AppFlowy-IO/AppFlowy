import 'package:fixnum/fixnum.dart';

extension DateConversion on Int64 {
  DateTime toDateTime() => DateTime.fromMillisecondsSinceEpoch(toInt() * 1000);

  DateTime? get dateTime =>
      toInt() != 0 ? DateTime.fromMillisecondsSinceEpoch(toInt() * 1000) : null;
}
