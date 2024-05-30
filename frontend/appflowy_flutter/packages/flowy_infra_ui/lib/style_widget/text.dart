import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const String _emojiFontFamily = 'noto color emoji';

class FlowyText extends StatelessWidget {
  final String text;
  final TextOverflow? overflow;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final int? maxLines;
  final Color? color;
  final TextDecoration? decoration;
  final bool selectable;
  final String? fontFamily;
  final List<String>? fallbackFontFamily;
  final double? lineHeight;
  final bool withTooltip;
  final StrutStyle? strutStyle;
  final bool isEmoji;

  const FlowyText(
    this.text, {
    super.key,
    this.overflow = TextOverflow.clip,
    this.fontSize,
    this.fontWeight,
    this.textAlign,
    this.color,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    this.fontFamily,
    this.fallbackFontFamily,
    this.lineHeight,
    this.withTooltip = false,
    this.isEmoji = false,
    this.strutStyle,
  });

  FlowyText.small(
    this.text, {
    super.key,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    this.fontFamily,
    this.fallbackFontFamily,
    this.lineHeight,
    this.withTooltip = false,
    this.isEmoji = false,
    this.strutStyle,
  })  : fontWeight = FontWeight.w400,
        fontSize = (Platform.isIOS || Platform.isAndroid) ? 14 : 12;

  const FlowyText.regular(
    this.text, {
    super.key,
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    this.fontFamily,
    this.fallbackFontFamily,
    this.lineHeight,
    this.withTooltip = false,
    this.isEmoji = false,
    this.strutStyle,
  }) : fontWeight = FontWeight.w400;

  const FlowyText.medium(
    this.text, {
    super.key,
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    this.fontFamily,
    this.fallbackFontFamily,
    this.lineHeight,
    this.withTooltip = false,
    this.isEmoji = false,
    this.strutStyle,
  }) : fontWeight = FontWeight.w500;

  const FlowyText.semibold(
    this.text, {
    super.key,
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    this.fontFamily,
    this.fallbackFontFamily,
    this.lineHeight,
    this.withTooltip = false,
    this.isEmoji = false,
    this.strutStyle,
  }) : fontWeight = FontWeight.w600;

  // Some emojis are not supported on Linux and Android, fallback to noto color emoji
  const FlowyText.emoji(
    this.text, {
    super.key,
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign = TextAlign.center,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    this.lineHeight,
    this.withTooltip = false,
    this.strutStyle = const StrutStyle(forceStrutHeight: true),
    this.isEmoji = true,
    this.fontFamily,
  })  : fontWeight = FontWeight.w400,
        fallbackFontFamily = null;

  @override
  Widget build(BuildContext context) {
    Widget child;

    var fontFamily = this.fontFamily;
    var fallbackFontFamily = this.fallbackFontFamily;
    if (isEmoji && (Platform.isLinux || Platform.isAndroid)) {
      fontFamily = _loadEmojiFontFamilyIfNeeded();
      if (fontFamily != null && fallbackFontFamily == null) {
        fallbackFontFamily = [fontFamily];
      }
    }

    var fontSize =
        this.fontSize ?? Theme.of(context).textTheme.bodyMedium!.fontSize!;
    if (Platform.isLinux && fontFamily == _emojiFontFamily) {
      fontSize = fontSize * 0.8;
    }

    final textStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          decoration: decoration,
          fontFamily: fontFamily,
          fontFamilyFallback: fallbackFontFamily,
          height: lineHeight,
        );

    if (selectable) {
      child = SelectableText(
        text,
        maxLines: maxLines,
        textAlign: textAlign,
        strutStyle: strutStyle,
        style: textStyle,
      );
    } else {
      child = Text(
        text,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: overflow ?? TextOverflow.clip,
        style: textStyle,
      );
    }

    if (withTooltip) {
      child = Tooltip(
        message: text,
        child: child,
      );
    }

    return child;
  }

  String? _loadEmojiFontFamilyIfNeeded() {
    if (Platform.isLinux || Platform.isAndroid) {
      return GoogleFonts.notoColorEmoji().fontFamily;
    }

    return null;
  }
}
