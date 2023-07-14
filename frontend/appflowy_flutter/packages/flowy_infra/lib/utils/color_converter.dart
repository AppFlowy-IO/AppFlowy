import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

class ColorConverter implements JsonConverter<Color, String> {
  const ColorConverter();

  static const Color fallback = Colors.transparent;

  @override
  Color fromJson(String radixString) {
    final int? color = int.tryParse(radixString);
    return color == null ? fallback : Color(color);
  }

  @override
  String toJson(Color color) => "0x${color.value.toRadixString(16)}";
}
