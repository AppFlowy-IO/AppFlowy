import 'package:appflowy_editor/src/document/attributes.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

///
/// Supported partial rendering types:
///   bold, italic,
///   underline, strikethrough,
///   color, font,
///   href
///
/// Supported global rendering types:
///   heading: h1, h2, h3, h4, h5, h6, ...
///   block quote,
///   list: ordered list, bulleted list,
///   code block
///
class StyleKey {
  static String bold = 'bold';
  static String italic = 'italic';
  static String underline = 'underline';
  static String strikethrough = 'strikethrough';
  static String color = 'color';
  static String backgroundColor = 'backgroundColor';
  static String font = 'font';
  static String href = 'href';

  static String subtype = 'subtype';
  static String heading = 'heading';
  static String h1 = 'h1';
  static String h2 = 'h2';
  static String h3 = 'h3';
  static String h4 = 'h4';
  static String h5 = 'h5';
  static String h6 = 'h6';

  static String bulletedList = 'bulleted-list';
  static String numberList = 'number-list';

  static String quote = 'quote';
  static String checkbox = 'checkbox';
  static String code = 'code';
  static String number = 'number';

  static List<String> partialStyleKeys = [
    StyleKey.bold,
    StyleKey.italic,
    StyleKey.underline,
    StyleKey.strikethrough,
    StyleKey.backgroundColor,
    StyleKey.href,
    StyleKey.code,
  ];

  static List<String> globalStyleKeys = [
    StyleKey.subtype,
    StyleKey.heading,
    StyleKey.checkbox,
    StyleKey.bulletedList,
    StyleKey.numberList,
    StyleKey.quote,
  ];
}

// TODO: customize
double defaultLinePadding = 8.0;
double baseFontSize = 16.0;
String defaultHighlightColor = '0x6000BCF0';
String defaultBackgroundColor = '0x00000000';
// TODO: customize.
Map<String, double> headingToFontSize = {
  StyleKey.h1: baseFontSize + 15,
  StyleKey.h2: baseFontSize + 12,
  StyleKey.h3: baseFontSize + 9,
  StyleKey.h4: baseFontSize + 6,
  StyleKey.h5: baseFontSize + 3,
  StyleKey.h6: baseFontSize,
};

extension NodeAttributesExtensions on Attributes {
  String? get heading {
    if (containsKey(StyleKey.subtype) &&
        containsKey(StyleKey.heading) &&
        this[StyleKey.subtype] == StyleKey.heading &&
        this[StyleKey.heading] is String) {
      return this[StyleKey.heading];
    }
    return null;
  }

  double get fontSize {
    if (heading != null) {
      return headingToFontSize[heading]!;
    }
    return baseFontSize;
  }

  bool get quote {
    return containsKey(StyleKey.quote);
  }

  Color? get quoteColor {
    if (quote) {
      return Colors.grey;
    }
    return null;
  }

  int? get number {
    if (containsKey(StyleKey.number) && this[StyleKey.number] is int) {
      return this[StyleKey.number];
    }
    return null;
  }

  bool get code {
    if (containsKey(StyleKey.code) && this[StyleKey.code] == true) {
      return this[StyleKey.code];
    }
    return false;
  }

  bool get check {
    if (containsKey(StyleKey.checkbox) && this[StyleKey.checkbox] is bool) {
      return this[StyleKey.checkbox];
    }
    return false;
  }
}

extension DeltaAttributesExtensions on Attributes {
  bool get bold {
    return (containsKey(StyleKey.bold) && this[StyleKey.bold] == true);
  }

  bool get italic {
    return (containsKey(StyleKey.italic) && this[StyleKey.italic] == true);
  }

  bool get underline {
    return (containsKey(StyleKey.underline) &&
        this[StyleKey.underline] == true);
  }

  bool get strikethrough {
    return (containsKey(StyleKey.strikethrough) &&
        this[StyleKey.strikethrough] == true);
  }

  Color? get color {
    if (containsKey(StyleKey.color) && this[StyleKey.color] is String) {
      return Color(
        int.parse(this[StyleKey.color]),
      );
    }
    return null;
  }

  Color? get backgroundColor {
    if (containsKey(StyleKey.backgroundColor) &&
        this[StyleKey.backgroundColor] is String) {
      return Color(
        int.parse(this[StyleKey.backgroundColor]),
      );
    }
    return null;
  }

  String? get font {
    // TODO: unspport now.
    return null;
  }

  String? get href {
    if (containsKey(StyleKey.href) && this[StyleKey.href] is String) {
      return this[StyleKey.href];
    }
    return null;
  }
}

class RichTextStyle {
  // TODO: customize
  RichTextStyle({
    required this.attributes,
    required this.text,
    this.gestureRecognizer,
    this.height = 1.5,
  });

  final Attributes attributes;
  final String text;
  final GestureRecognizer? gestureRecognizer;
  final double height;

  TextSpan toTextSpan() => _toTextSpan(height);

  double get topPadding {
    return 0;
  }

  TextSpan _toTextSpan(double? height) {
    return TextSpan(
      text: text,
      recognizer: _recognizer,
      style: TextStyle(
        fontWeight: _fontWeight,
        fontStyle: _fontStyle,
        fontSize: _fontSize,
        color: _textColor,
        decoration: _textDecoration,
        background: _background,
        height: height,
      ),
    );
  }

  Paint? get _background {
    if (_backgroundColor != null) {
      return Paint()
        ..color = _backgroundColor!
        ..strokeWidth = 24.0
        ..style = PaintingStyle.fill
        ..strokeJoin = StrokeJoin.round;
    }
    return null;
  }

  // bold
  FontWeight get _fontWeight {
    if (attributes.bold) {
      return FontWeight.bold;
    }
    return FontWeight.normal;
  }

  // underline or strikethrough
  TextDecoration get _textDecoration {
    var decorations = [TextDecoration.none];
    if (attributes.underline || attributes.href != null) {
      decorations.add(TextDecoration.underline);
    }
    if (attributes.strikethrough) {
      decorations.add(TextDecoration.lineThrough);
    }
    return TextDecoration.combine(decorations);
  }

  // font
  FontStyle get _fontStyle =>
      attributes.italic ? FontStyle.italic : FontStyle.normal;

  // text color
  Color get _textColor {
    if (attributes.href != null) {
      return Colors.lightBlue;
    }
    if (attributes.code) {
      return Colors.lightBlue.withOpacity(0.8);
    }
    return attributes.color ?? Colors.black;
  }

  Color? get _backgroundColor {
    if (attributes.backgroundColor != null) {
      return attributes.backgroundColor!;
    } else if (attributes.code) {
      return Colors.blue.shade300.withOpacity(0.3);
    }
    return null;
  }

  // font size
  double get _fontSize {
    return baseFontSize;
  }

  // recognizer
  GestureRecognizer? get _recognizer {
    return gestureRecognizer;
  }
}
