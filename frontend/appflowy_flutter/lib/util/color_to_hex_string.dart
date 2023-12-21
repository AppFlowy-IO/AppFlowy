import 'package:flutter/material.dart';

extension ColorExtensionn on Color {
  /// return a hex string in 0xff000000 format
  String toHexString() {
    return '0x${value.toRadixString(16).padLeft(8, '0')}';
  }
}
