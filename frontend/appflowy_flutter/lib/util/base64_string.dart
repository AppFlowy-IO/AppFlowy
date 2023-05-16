import 'dart:convert';

extension Base64Encode on String {
  String get base64 => base64Encode(utf8.encode(this));
}
