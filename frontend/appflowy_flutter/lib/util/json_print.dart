import 'dart:convert';

import 'package:appflowy_backend/log.dart';

const JsonEncoder _encoder = JsonEncoder.withIndent('  ');
void prettyPrintJson(Object? object) {
  Log.debug(_encoder.convert(object));
}
