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

  const FlowyText(
    this.text, {
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
    Key? key,
  }) : super(key: key);

  FlowyText.small(
    this.text, {
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    this.fontFamily,
    this.fallbackFontFamily,
    Key? key,
  })  : fontWeight = FontWeight.w400,
        fontSize = (Platform.isIOS || Platform.isAndroid) ? 14 : 12,
        super(key: key);

  const FlowyText.regular(
    this.text, {
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    this.fontFamily,
    this.fallbackFontFamily,
    Key? key,
  })  : fontWeight = FontWeight.w400,
        super(key: key);

  const FlowyText.medium(
    this.text, {
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    this.fontFamily,
    this.fallbackFontFamily,
    Key? key,
  })  : fontWeight = FontWeight.w500,
        super(key: key);

  const FlowyText.semibold(
    this.text, {
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    this.fontFamily,
    this.fallbackFontFamily,
    Key? key,
  })  : fontWeight = FontWeight.w600,
        super(key: key);

  // Some emojis are not supported on Linux and Android, fallback to noto color emoji
  const FlowyText.emoji(
    this.text, {
    this.fontSize,
    this.overflow,
    this.color,
    this.textAlign,
    this.maxLines = 1,
    this.decoration,
    this.selectable = false,
    Key? key,
  })  : fontWeight = FontWeight.w400,
        fontFamily = 'noto color emoji',
        fallbackFontFamily = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectable) {
      return SelectableText(
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
            ),
      );
    } else {
      return Text(
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
            ),
      );
    }
  }
}
