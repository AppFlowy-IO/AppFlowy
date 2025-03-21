import 'package:flutter/material.dart';

class LinkStyle {
  static const borderColor = Color(0xFFE8ECF3);
  static const textTertiary = Color(0xFF99A1A8);
  static const fillThemeThick = Color(0xFF00B5FF);
  static const shadowMedium = Color(0x1F22251F);
  static const textPrimary = Color(0xFF1F2329);

  static InputDecoration buildLinkTextFieldInputDecoration(String hintText) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
      borderSide: BorderSide(color: LinkStyle.borderColor),
    );
    final enableBorder = border.copyWith(
      borderSide: BorderSide(color: LinkStyle.fillThemeThick),
    );
    const hintStyle = TextStyle(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
      color: LinkStyle.textTertiary,
    );
    return InputDecoration(
      hintText: hintText,
      hintStyle: hintStyle,
      contentPadding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      isDense: true,
      border: border,
      enabledBorder: border,
      focusedBorder: enableBorder,
    );
  }
}
