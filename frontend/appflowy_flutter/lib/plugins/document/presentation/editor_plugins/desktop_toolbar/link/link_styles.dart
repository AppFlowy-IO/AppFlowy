import 'package:appflowy/util/theme_extension.dart';
import 'package:flutter/material.dart';

class LinkStyle {
  static const textTertiary = Color(0xFF99A1A8);
  static const textStatusError = Color(0xffE71D32);
  static const fillThemeThick = Color(0xFF00B5FF);
  static const shadowMedium = Color(0x1F22251F);
  static const textPrimary = Color(0xFF1F2329);

  static Color borderColor(BuildContext context) =>
      Theme.of(context).isLightMode ? Color(0xFFE8ECF3) : Color(0x64BDBDBD);

  static InputDecoration buildLinkTextFieldInputDecoration(
    String hintText,
    BuildContext context, {
    bool showErrorBorder = false,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8.0)),
      borderSide: BorderSide(color: borderColor(context)),
    );
    final enableBorder = border.copyWith(
      borderSide: BorderSide(
        color: showErrorBorder
            ? LinkStyle.textStatusError
            : LinkStyle.fillThemeThick,
      ),
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
