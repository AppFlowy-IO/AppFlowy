import 'package:fixnum/fixnum.dart';

extension DateConversion on Int64 {
  DateTime toDateTime() => DateTime.fromMillisecondsSinceEpoch(toInt() * 1000);
}
