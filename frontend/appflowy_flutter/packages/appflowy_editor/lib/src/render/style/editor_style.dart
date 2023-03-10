import 'package:flutter/material.dart';

Iterable<ThemeExtension<dynamic>> get lightEditorStyleExtension => [
      EditorStyle.light,
    ];

Iterable<ThemeExtension<dynamic>> get darkEditorStyleExtension => [
      EditorStyle.dark,
    ];

class EditorStyle extends ThemeExtension<EditorStyle> {
  // Editor styles
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? cursorColor;
  final Color? selectionColor;

  // Selection menu styles
  final Color? selectionMenuBackgroundColor;
  final Color? selectionMenuItemTextColor;
  final Color? selectionMenuItemIconColor;
  final Color? selectionMenuItemSelectedTextColor;
  final Color? selectionMenuItemSelectedIconColor;
  final Color? selectionMenuItemSelectedColor;

  // Text styles
  final EdgeInsets? textPadding;
  final TextStyle? textStyle;
  final TextStyle? placeholderTextStyle;
  final double lineHeight;

  // Rich text styles
  final TextStyle? bold;
  final TextStyle? italic;
  final TextStyle? underline;
  final TextStyle? strikethrough;
  final TextStyle? href;
  final TextStyle? code;
  final String? highlightColorHex;

  EditorStyle({
    required this.padding,
    required this.backgroundColor,
    required this.cursorColor,
    required this.selectionColor,
    required this.selectionMenuBackgroundColor,
    required this.selectionMenuItemTextColor,
    required this.selectionMenuItemIconColor,
    required this.selectionMenuItemSelectedTextColor,
    required this.selectionMenuItemSelectedIconColor,
    required this.selectionMenuItemSelectedColor,
    required this.textPadding,
    required this.textStyle,
    required this.placeholderTextStyle,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.strikethrough,
    required this.href,
    required this.code,
    required this.highlightColorHex,
    required this.lineHeight,
  });

  @override
  EditorStyle copyWith({
    EdgeInsets? padding,
    Color? backgroundColor,
    Color? cursorColor,
    Color? selectionColor,
    Color? selectionMenuBackgroundColor,
    Color? selectionMenuItemTextColor,
    Color? selectionMenuItemIconColor,
    Color? selectionMenuItemSelectedTextColor,
    Color? selectionMenuItemSelectedIconColor,
    Color? selectionMenuItemSelectedColor,
    TextStyle? textStyle,
    TextStyle? placeholderTextStyle,
    TextStyle? bold,
    TextStyle? italic,
    TextStyle? underline,
    TextStyle? strikethrough,
    TextStyle? href,
    TextStyle? code,
    String? highlightColorHex,
    double? lineHeight,
  }) {
    return EditorStyle(
      padding: padding ?? this.padding,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      cursorColor: cursorColor ?? this.cursorColor,
      selectionColor: selectionColor ?? this.selectionColor,
      selectionMenuBackgroundColor:
          selectionMenuBackgroundColor ?? this.selectionMenuBackgroundColor,
      selectionMenuItemTextColor:
          selectionMenuItemTextColor ?? this.selectionMenuItemTextColor,
      selectionMenuItemIconColor:
          selectionMenuItemIconColor ?? this.selectionMenuItemIconColor,
      selectionMenuItemSelectedTextColor: selectionMenuItemSelectedTextColor ??
          this.selectionMenuItemSelectedTextColor,
      selectionMenuItemSelectedIconColor: selectionMenuItemSelectedIconColor ??
          this.selectionMenuItemSelectedIconColor,
      selectionMenuItemSelectedColor:
          selectionMenuItemSelectedColor ?? this.selectionMenuItemSelectedColor,
      textPadding: textPadding ?? textPadding,
      textStyle: textStyle ?? this.textStyle,
      placeholderTextStyle: placeholderTextStyle ?? this.placeholderTextStyle,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      href: href ?? this.href,
      code: code ?? this.code,
      highlightColorHex: highlightColorHex ?? this.highlightColorHex,
      lineHeight: lineHeight ?? this.lineHeight,
    );
  }

  @override
  ThemeExtension<EditorStyle> lerp(
      ThemeExtension<EditorStyle>? other, double t) {
    if (other == null || other is! EditorStyle) {
      return this;
    }
    return EditorStyle(
      padding: EdgeInsets.lerp(padding, other.padding, t),
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      cursorColor: Color.lerp(cursorColor, other.cursorColor, t),
      textPadding: EdgeInsets.lerp(textPadding, other.textPadding, t),
      selectionColor: Color.lerp(selectionColor, other.selectionColor, t),
      selectionMenuBackgroundColor: Color.lerp(
          selectionMenuBackgroundColor, other.selectionMenuBackgroundColor, t),
      selectionMenuItemTextColor: Color.lerp(
          selectionMenuItemTextColor, other.selectionMenuItemTextColor, t),
      selectionMenuItemIconColor: Color.lerp(
          selectionMenuItemIconColor, other.selectionMenuItemIconColor, t),
      selectionMenuItemSelectedTextColor: Color.lerp(
          selectionMenuItemSelectedTextColor,
          other.selectionMenuItemSelectedTextColor,
          t),
      selectionMenuItemSelectedIconColor: Color.lerp(
          selectionMenuItemSelectedIconColor,
          other.selectionMenuItemSelectedIconColor,
          t),
      selectionMenuItemSelectedColor: Color.lerp(selectionMenuItemSelectedColor,
          other.selectionMenuItemSelectedColor, t),
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t),
      placeholderTextStyle:
          TextStyle.lerp(placeholderTextStyle, other.placeholderTextStyle, t),
      bold: TextStyle.lerp(bold, other.bold, t),
      italic: TextStyle.lerp(italic, other.italic, t),
      underline: TextStyle.lerp(underline, other.underline, t),
      strikethrough: TextStyle.lerp(strikethrough, other.strikethrough, t),
      href: TextStyle.lerp(href, other.href, t),
      code: TextStyle.lerp(code, other.code, t),
      highlightColorHex: highlightColorHex,
      lineHeight: lineHeight,
    );
  }

  static EditorStyle? of(BuildContext context) {
    return Theme.of(context).extension<EditorStyle>();
  }

  static final light = EditorStyle(
    padding: const EdgeInsets.fromLTRB(200.0, 0.0, 200.0, 0.0),
    backgroundColor: Colors.white,
    cursorColor: const Color(0xFF00BCF0),
    selectionColor: const Color.fromARGB(53, 111, 201, 231),
    selectionMenuBackgroundColor: const Color(0xFFFFFFFF),
    selectionMenuItemTextColor: const Color(0xFF333333),
    selectionMenuItemIconColor: const Color(0xFF333333),
    selectionMenuItemSelectedTextColor: const Color.fromARGB(255, 56, 91, 247),
    selectionMenuItemSelectedIconColor: const Color.fromARGB(255, 56, 91, 247),
    selectionMenuItemSelectedColor: const Color(0xFFE0F8FF),
    textPadding: const EdgeInsets.symmetric(vertical: 8.0),
    textStyle: const TextStyle(fontSize: 16.0, color: Colors.black),
    placeholderTextStyle: const TextStyle(fontSize: 16.0, color: Colors.grey),
    bold: const TextStyle(fontWeight: FontWeight.bold),
    italic: const TextStyle(fontStyle: FontStyle.italic),
    underline: const TextStyle(decoration: TextDecoration.underline),
    strikethrough: const TextStyle(decoration: TextDecoration.lineThrough),
    href: const TextStyle(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    ),
    code: const TextStyle(
      fontFamily: 'monospace',
      color: Color(0xFF00BCF0),
      backgroundColor: Color(0xFFE0F8FF),
    ),
    highlightColorHex: '0x6000BCF0',
    lineHeight: 1.5,
  );

  static final dark = light.copyWith(
    backgroundColor: Colors.black,
    textStyle: const TextStyle(fontSize: 16.0, color: Colors.white),
    placeholderTextStyle: TextStyle(
      fontSize: 16.0,
      color: Colors.white.withOpacity(0.3),
    ),
    selectionMenuBackgroundColor: const Color(0xFF282E3A),
    selectionMenuItemTextColor: const Color(0xFFBBC3CD),
    selectionMenuItemIconColor: const Color(0xFFBBC3CD),
    selectionMenuItemSelectedTextColor: const Color(0xFF131720),
    selectionMenuItemSelectedIconColor: const Color(0xFF131720),
    selectionMenuItemSelectedColor: const Color(0xFF00BCF0),
  );
}
