import 'package:flutter/material.dart';

extension EncodeString on String {
  static const _specialCharacters = r'\/:*?"<>| ';

  /// Encode a string to a file name.
  ///
  /// Normalizes the string to remove special characters and replaces the "\/:*?"<>|" with underscores.
  String toFileName() {
    final buffer = StringBuffer();
    for (final character in characters) {
      if (_specialCharacters.contains(character)) {
        buffer.write('_');
      } else {
        buffer.write(character);
      }
    }
    return buffer.toString();
  }
}
