import 'package:flowy_editor/document/attributes.dart';
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
  static String highlightColor = 'highlightColor';
  static String font = 'font';
  static String href = 'href';

  static String quote = 'quote';
  static String list = 'list';
  static String number = 'number';
  static String todo = 'todo';
  static String code = 'code';

  static String subtype = 'subtype';
  static String check = 'checkbox';
  static String heading = 'heading';
}

double baseFontSize = 16.0;
// TODO: customize.
Map<String, double> headingToFontSize = {
  'h1': baseFontSize + 15,
  'h2': baseFontSize + 12,
  'h3': baseFontSize + 9,
  'h4': baseFontSize + 6,
  'h5': baseFontSize + 3,
  'h6': baseFontSize,
};

extension NodeAttributesExtensions on Attributes {
  String? get heading {
    if (containsKey(StyleKey.heading) && this[StyleKey.heading] is String) {
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

  String? get list {
    if (containsKey(StyleKey.list) && this[StyleKey.list] is String) {
      return this[StyleKey.list];
    }
    return null;
  }

  int? get number {
    if (containsKey(StyleKey.number) && this[StyleKey.number] is int) {
      return this[StyleKey.number];
    }
    return null;
  }

  bool get todo {
    if (containsKey(StyleKey.todo) && this[StyleKey.todo] is bool) {
      return this[StyleKey.todo];
    }
    return false;
  }

  bool get code {
    if (containsKey(StyleKey.code) && this[StyleKey.code] == true) {
      return this[StyleKey.code];
    }
    return false;
  }

  bool get check {
    if (containsKey(StyleKey.check) && this[StyleKey.check] is bool) {
      return this[StyleKey.check];
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

  Color? get hightlightColor {
    if (containsKey(StyleKey.highlightColor) &&
        this[StyleKey.highlightColor] is String) {
      return Color(
        int.parse(this[StyleKey.highlightColor]),
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
  });

  final Attributes attributes;
  final String text;

  TextSpan toTextSpan() {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        fontSize: fontSize,
        color: textColor,
        backgroundColor: backgroundColor,
        decoration: textDecoration,
      ),
      recognizer: recognizer,
    );
  }

  // bold
  FontWeight get fontWeight {
    if (attributes.bold) {
      return FontWeight.bold;
    }
    return FontWeight.normal;
  }

  // underline or strikethrough
  TextDecoration get textDecoration {
    if (attributes.underline || attributes.href != null) {
      return TextDecoration.underline;
    } else if (attributes.strikethrough) {
      return TextDecoration.lineThrough;
    }
    return TextDecoration.none;
  }

  // font
  FontStyle get fontStyle =>
      attributes.italic ? FontStyle.italic : FontStyle.normal;

  // text color
  Color get textColor {
    if (attributes.href != null) {
      return Colors.lightBlue;
    }
    return attributes.color ?? Colors.black;
  }

  Color get backgroundColor {
    return attributes.hightlightColor ?? Colors.transparent;
  }

  // font size
  double get fontSize {
    return baseFontSize;
  }

  // recognizer
  GestureRecognizer? get recognizer {
    final href = attributes.href;
    if (href != null) {
      return TapGestureRecognizer()
        ..onTap = () async {
          // FIXME: launch the url
        };
    }
    return null;
  }
}
