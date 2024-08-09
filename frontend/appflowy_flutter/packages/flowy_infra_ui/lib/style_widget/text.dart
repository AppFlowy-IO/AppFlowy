import 'dart:io';

import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final bool withTooltip;
  final StrutStyle? strutStyle;
  final bool isEmoji;

  /// this is used to control the line height in Flutter.
  final double? lineHeight;

  /// this is used to control the line height from Figma.
  final double? figmaLineHeight;

  final bool optimizeEmojiAlign;

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
    // https://api.flutter.dev/flutter/painting/TextStyle/height.html
    this.lineHeight = 1,
    this.figmaLineHeight,
    this.withTooltip = false,
    this.isEmoji = false,
    this.strutStyle,
    this.optimizeEmojiAlign = false,
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
    this.figmaLineHeight,
    this.optimizeEmojiAlign = false,
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
    this.figmaLineHeight,
    this.optimizeEmojiAlign = false,
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
    this.lineHeight = 1,
    this.withTooltip = false,
    this.isEmoji = false,
    this.strutStyle,
    this.figmaLineHeight,
    this.optimizeEmojiAlign = false,
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
    this.lineHeight = 1,
    this.withTooltip = false,
    this.isEmoji = false,
    this.strutStyle,
    this.figmaLineHeight,
    this.optimizeEmojiAlign = false,
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
    this.figmaLineHeight,
    this.optimizeEmojiAlign = false,
  })  : fontWeight = FontWeight.w400,
        fallbackFontFamily = null;

  @override
  Widget build(BuildContext context) {
    Widget child;

    var fontFamily = this.fontFamily;
    var fallbackFontFamily = this.fallbackFontFamily;
    var fontSize =
        this.fontSize ?? Theme.of(context).textTheme.bodyMedium!.fontSize!;
    if (isEmoji && _useNotoColorEmoji) {
      fontFamily = _loadEmojiFontFamilyIfNeeded();
      if (fontFamily != null && fallbackFontFamily == null) {
        fallbackFontFamily = [fontFamily];
      }
    }

    if (isEmoji && (_useNotoColorEmoji || Platform.isWindows)) {
      fontSize = fontSize * 0.8;
    }

    double? lineHeight;
    if (this.lineHeight != null) {
      lineHeight = this.lineHeight!;
    } else if (figmaLineHeight != null) {
      lineHeight = figmaLineHeight! / fontSize;
    }

    final textStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          decoration: decoration,
          fontFamily: fontFamily,
          fontFamilyFallback: fallbackFontFamily,
          height: lineHeight,
          leadingDistribution: isEmoji && optimizeEmojiAlign
              ? TextLeadingDistribution.even
              : null,
        );

    if (selectable) {
      child = IntrinsicHeight(
        child: SelectableText(
          text,
          maxLines: maxLines,
          textAlign: textAlign,
          style: textStyle,
        ),
      );
    } else {
      child = Text(
        text,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: overflow ?? TextOverflow.clip,
        style: textStyle,
        strutStyle: ((Platform.isMacOS || Platform.isLinux) & !isEmoji) ||
                (isEmoji && optimizeEmojiAlign)
            ? StrutStyle.fromTextStyle(
                textStyle,
                forceStrutHeight: true,
                leadingDistribution: TextLeadingDistribution.even,
                height: lineHeight,
              )
            : null,
      );
    }

    if (withTooltip) {
      child = FlowyTooltip(
        message: text,
        child: child,
      );
    }

    return child;
  }

  String? _loadEmojiFontFamilyIfNeeded() {
    if (_useNotoColorEmoji) {
      return GoogleFonts.notoColorEmoji().fontFamily;
    }

    return null;
  }

  bool get _useNotoColorEmoji => Platform.isLinux || Platform.isAndroid;
}
