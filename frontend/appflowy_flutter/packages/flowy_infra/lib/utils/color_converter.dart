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
  String toJson(Color color) {
    final alpha = (color.a * 255).toInt().toRadixString(16).padLeft(2, '0');
    final red = (color.r * 255).toInt().toRadixString(16).padLeft(2, '0');
    final green = (color.g * 255).toInt().toRadixString(16).padLeft(2, '0');
    final blue = (color.b * 255).toInt().toRadixString(16).padLeft(2, '0');

    return '0x$alpha$red$green$blue'.toLowerCase();
  }
}
