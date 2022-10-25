import 'package:flutter/material.dart';

import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/extensions/attributes_extension.dart';

class EditorStyleV2 extends ThemeExtension<EditorStyleV2> {
  // Editor styles
  final EdgeInsets? padding;
  final Color? cursorColor;
  final Color? selectionColor;

  // Text styles
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

  EditorStyleV2({
    required this.padding,
    required this.cursorColor,
    required this.selectionColor,
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
  EditorStyleV2 copyWith({
    EdgeInsets? padding,
    Color? cursorColor,
    Color? selectionColor,
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
    return EditorStyleV2(
      padding: padding ?? this.padding,
      cursorColor: cursorColor ?? this.cursorColor,
      selectionColor: selectionColor ?? this.selectionColor,
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
  ThemeExtension<EditorStyleV2> lerp(
      ThemeExtension<EditorStyleV2>? other, double t) {
    if (other == null || other is! EditorStyleV2) {
      return this;
    }
    return EditorStyleV2(
      padding: EdgeInsets.lerp(padding, other.padding, t),
      cursorColor: Color.lerp(cursorColor, other.cursorColor, t),
      selectionColor: Color.lerp(selectionColor, other.selectionColor, t),
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
}

typedef PluginStyler = Object Function(EditorState editorState, Node node);
typedef PluginStyle = Map<String, PluginStyler>;

/// Editor style configuration
class EditorStyle {
  EditorStyle({
    required this.padding,
    required this.textStyle,
    required this.cursorColor,
    required this.selectionColor,
    Map<String, PluginStyle> pluginStyles = const {},
  }) {
    _pluginStyles.addAll(pluginStyles);
  }

  EditorStyle.defaultStyle()
      : padding = const EdgeInsets.fromLTRB(200.0, 0.0, 200.0, 0.0),
        textStyle = BuiltInTextStyle.builtIn(),
        cursorColor = const Color(0xFF00BCF0),
        selectionColor = const Color.fromARGB(53, 111, 201, 231);

  /// The margin of the document context from the editor.
  final EdgeInsets padding;
  final BuiltInTextStyle textStyle;
  final Color cursorColor;
  final Color selectionColor;

  final Map<String, PluginStyle> _pluginStyles = Map.from(builtInTextStylers);

  Object? style(EditorState editorState, Node node, String key) {
    final styler = _pluginStyles[node.id]?[key];
    if (styler != null) {
      return styler(editorState, node);
    }
    return null;
  }

  @override
  EditorStyle copyWith({
    EdgeInsets? padding,
    BuiltInTextStyle? textStyle,
    Color? cursorColor,
    Color? selectionColor,
    Map<String, PluginStyle>? pluginStyles,
  }) {
    return EditorStyle(
      padding: padding ?? this.padding,
      textStyle: textStyle ?? this.textStyle,
      cursorColor: cursorColor ?? this.cursorColor,
      selectionColor: selectionColor ?? this.selectionColor,
      pluginStyles: pluginStyles ?? {},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EditorStyle &&
        other.padding == padding &&
        other.textStyle == textStyle &&
        other.cursorColor == cursorColor &&
        other.selectionColor == selectionColor;
  }

  @override
  int get hashCode {
    return padding.hashCode ^
        textStyle.hashCode ^
        cursorColor.hashCode ^
        selectionColor.hashCode;
  }
}

PluginStyle get builtInPluginStyle => Map.from({
      'padding': (_, __) => const EdgeInsets.symmetric(vertical: 8.0),
      'textStyle': (_, __) => const TextStyle(),
      'iconSize': (_, __) => const Size.square(20.0),
      'iconPadding': (_, __) => const EdgeInsets.only(right: 5.0),
    });

Map<String, PluginStyle> builtInTextStylers = {
  'text': builtInPluginStyle,
  'text/checkbox': builtInPluginStyle
    ..update(
      'textStyle',
      (_) => (EditorState editorState, Node node) {
        if (node is TextNode && node.attributes.check == true) {
          return const TextStyle(
            color: Colors.grey,
            decoration: TextDecoration.lineThrough,
          );
        }
        return const TextStyle();
      },
    ),
  'text/heading': builtInPluginStyle
    ..update(
      'textStyle',
      (_) => (EditorState editorState, Node node) {
        final headingToFontSize = {
          'h1': 32.0,
          'h2': 28.0,
          'h3': 24.0,
          'h4': 18.0,
          'h5': 18.0,
          'h6': 18.0,
        };
        final fontSize = headingToFontSize[node.attributes.heading] ?? 18.0;
        return TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold);
      },
    ),
  'text/bulleted-list': builtInPluginStyle,
  'text/number-list': builtInPluginStyle
    ..addAll({
      'numberColor': (EditorState editorState, Node node) {
        return Colors.black;
      },
      'iconPadding': (EditorState editorState, Node node) {
        return const EdgeInsets.only(left: 5.0, right: 5.0);
      },
    }),
  'text/bulleted-list': builtInPluginStyle
    ..addAll({
      'bulletColor': (EditorState editorState, Node node) {
        return Colors.black;
      },
    }),
  'text/quote': builtInPluginStyle,
  'image': builtInPluginStyle,
};

class BuiltInTextStyle {
  const BuiltInTextStyle({
    required this.defaultTextStyle,
    required this.defaultPlaceholderTextStyle,
    required this.bold,
    required this.italic,
    required this.underline,
    required this.strikethrough,
    required this.href,
    required this.code,
    this.highlightColorHex = '0x6000BCF0',
    this.lineHeight = 1.5,
  });

  final TextStyle defaultTextStyle;
  final TextStyle defaultPlaceholderTextStyle;
  final TextStyle bold;
  final TextStyle italic;
  final TextStyle underline;
  final TextStyle strikethrough;
  final TextStyle href;
  final TextStyle code;
  final String highlightColorHex;
  final double lineHeight;

  BuiltInTextStyle.builtIn()
      : defaultTextStyle = const TextStyle(fontSize: 16.0, color: Colors.black),
        defaultPlaceholderTextStyle =
            const TextStyle(fontSize: 16.0, color: Colors.grey),
        bold = const TextStyle(fontWeight: FontWeight.bold),
        italic = const TextStyle(fontStyle: FontStyle.italic),
        underline = const TextStyle(decoration: TextDecoration.underline),
        strikethrough = const TextStyle(decoration: TextDecoration.lineThrough),
        href = const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        code = const TextStyle(
          fontFamily: 'monospace',
          color: Color(0xFF00BCF0),
          backgroundColor: Color(0xFFE0F8FF),
        ),
        highlightColorHex = '0x6000BCF0',
        lineHeight = 1.5;

  BuiltInTextStyle.builtInDarkMode()
      : defaultTextStyle = const TextStyle(fontSize: 16.0, color: Colors.white),
        defaultPlaceholderTextStyle = TextStyle(
          fontSize: 16.0,
          color: Colors.white.withOpacity(0.3),
        ),
        bold = const TextStyle(fontWeight: FontWeight.bold),
        italic = const TextStyle(fontStyle: FontStyle.italic),
        underline = const TextStyle(decoration: TextDecoration.underline),
        strikethrough = const TextStyle(decoration: TextDecoration.lineThrough),
        href = const TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
        code = const TextStyle(
          fontFamily: 'monospace',
          color: Color(0xFF00BCF0),
          backgroundColor: Color(0xFFE0F8FF),
        ),
        highlightColorHex = '0x6000BCF0',
        lineHeight = 1.5;

  BuiltInTextStyle copyWith({
    TextStyle? defaultTextStyle,
    TextStyle? defaultPlaceholderTextStyle,
    TextStyle? bold,
    TextStyle? italic,
    TextStyle? underline,
    TextStyle? strikethrough,
    TextStyle? href,
    TextStyle? code,
    String? highlightColorHex,
    double? lineHeight,
  }) {
    return BuiltInTextStyle(
      defaultTextStyle: defaultTextStyle ?? this.defaultTextStyle,
      defaultPlaceholderTextStyle:
          defaultPlaceholderTextStyle ?? this.defaultPlaceholderTextStyle,
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BuiltInTextStyle &&
        other.defaultTextStyle == defaultTextStyle &&
        other.defaultPlaceholderTextStyle == defaultPlaceholderTextStyle &&
        other.bold == bold &&
        other.italic == italic &&
        other.underline == underline &&
        other.strikethrough == strikethrough &&
        other.href == href &&
        other.code == code &&
        other.highlightColorHex == highlightColorHex &&
        other.lineHeight == lineHeight;
  }

  @override
  int get hashCode {
    return defaultTextStyle.hashCode ^
        defaultPlaceholderTextStyle.hashCode ^
        bold.hashCode ^
        italic.hashCode ^
        underline.hashCode ^
        strikethrough.hashCode ^
        href.hashCode ^
        code.hashCode ^
        highlightColorHex.hashCode ^
        lineHeight.hashCode;
  }
}
