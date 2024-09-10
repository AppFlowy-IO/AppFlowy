import 'dart:io';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// used to prevent loading font from google fonts every time
List<String>? _cachedFallbackFontFamily;

// Some emojis are not supported by the default font on Android or Linux, fallback to noto color emoji
class EmojiText extends StatelessWidget {
  const EmojiText({
    super.key,
    required this.emoji,
    required this.fontSize,
    this.textAlign,
    this.lineHeight,
  });

  final String emoji;
  final double fontSize;
  final TextAlign? textAlign;
  final double? lineHeight;

  @override
  Widget build(BuildContext context) {
    _loadFallbackFontFamily();
    return FlowyText(
      emoji,
      fontSize: fontSize,
      textAlign: textAlign,
      strutStyle: const StrutStyle(forceStrutHeight: true),
      fallbackFontFamily: _cachedFallbackFontFamily,
      lineHeight: lineHeight,
    );
  }

  void _loadFallbackFontFamily() {
    if (Platform.isLinux) {
      final notoColorEmoji = GoogleFonts.notoColorEmoji().fontFamily;
      if (notoColorEmoji != null) {
        _cachedFallbackFontFamily = [notoColorEmoji];
      }
    }
  }
}
