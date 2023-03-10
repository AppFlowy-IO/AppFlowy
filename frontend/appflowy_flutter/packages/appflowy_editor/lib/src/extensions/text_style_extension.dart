import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

extension TextSpanExtensions on TextSpan {
  TextSpan copyWith({
    String? text,
    TextStyle? style,
    List<InlineSpan>? children,
    GestureRecognizer? recognizer,
    String? semanticsLabel,
  }) {
    return TextSpan(
      text: text ?? this.text,
      style: style ?? this.style,
      children: children ?? this.children,
      recognizer: recognizer ?? this.recognizer,
      semanticsLabel: semanticsLabel ?? this.semanticsLabel,
    );
  }

  TextSpan updateTextStyle(TextStyle? other) {
    if (other == null) {
      return this;
    }
    return copyWith(
      style: style?.combine(other),
      children: children?.map((child) {
        if (child is TextSpan) {
          return child.updateTextStyle(other);
        }
        return child;
      }).toList(growable: false),
    );
  }
}

extension TextStyleExtensions on TextStyle {
  TextStyle combine(TextStyle? other) {
    if (other == null) {
      return this;
    }
    if (!other.inherit) {
      return other;
    }

    return copyWith(
      color: other.color,
      backgroundColor: other.backgroundColor,
      fontSize: other.fontSize,
      fontWeight: other.fontWeight,
      fontStyle: other.fontStyle,
      letterSpacing: other.letterSpacing,
      wordSpacing: other.wordSpacing,
      textBaseline: other.textBaseline,
      height: other.height,
      leadingDistribution: other.leadingDistribution,
      locale: other.locale,
      foreground: other.foreground,
      background: other.background,
      shadows: other.shadows,
      fontFeatures: other.fontFeatures,
      decoration: TextDecoration.combine([
        if (decoration != null) decoration!,
        if (other.decoration != null) other.decoration!,
      ]),
      decorationColor: other.decorationColor,
      decorationStyle: other.decorationStyle,
      decorationThickness: other.decorationThickness,
      fontFamilyFallback: other.fontFamilyFallback,
      overflow: other.overflow,
    );
  }
}
