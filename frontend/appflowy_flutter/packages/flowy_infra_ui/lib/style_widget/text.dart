import 'dart:io';

import 'package:flutter/material.dart';

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
  }) : fontWeight = FontWeight.w600;

  // Some emojis are not supported on Linux and Android, fallback to noto color emoji
  const FlowyText.emoji(
    this.text, {
    super.key,
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    this.lineHeight,
    this.withTooltip = false,
  })  : fontWeight = FontWeight.w400,
        fontFamily = 'noto color emoji',
        fallbackFontFamily = null;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (selectable) {
      child = SelectableText(
        text,
        maxLines: maxLines,
        textAlign: textAlign,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              decoration: decoration,
              fontFamily: fontFamily,
              fontFamilyFallback: fallbackFontFamily,
              height: lineHeight,
            ),
      );
    } else {
      child = Text(
        text,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: overflow ?? TextOverflow.clip,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              decoration: decoration,
              fontFamily: fontFamily,
              fontFamilyFallback: fallbackFontFamily,
              height: lineHeight,
            ),
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
}
