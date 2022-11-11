import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

const _baseFontSize = 14.0;

EditorStyle customEditorTheme(BuildContext context) {
  var editorStyle = Theme.of(context).brightness == Brightness.dark
      ? EditorStyle.dark
      : EditorStyle.light;
  editorStyle = editorStyle.copyWith(
    textStyle: editorStyle.textStyle?.copyWith(
      fontFamily: 'poppins',
      fontSize: _baseFontSize,
    ),
    placeholderTextStyle: editorStyle.placeholderTextStyle?.copyWith(
      fontFamily: 'poppins',
      fontSize: _baseFontSize,
    ),
    bold: editorStyle.bold?.copyWith(
      fontWeight: FontWeight.w500,
    ),
  );
  return editorStyle;
}

Iterable<ThemeExtension<dynamic>> customPluginTheme(BuildContext context) {
  const basePadding = 12.0;
  var headingPluginStyle = Theme.of(context).brightness == Brightness.dark
      ? HeadingPluginStyle.dark
      : HeadingPluginStyle.light;
  headingPluginStyle = headingPluginStyle.copyWith(
    textStyle: (EditorState editorState, Node node) {
      final headingToFontSize = {
        'h1': _baseFontSize + 12,
        'h2': _baseFontSize + 8,
        'h3': _baseFontSize + 4,
        'h4': _baseFontSize,
        'h5': _baseFontSize,
        'h6': _baseFontSize,
      };
      final fontSize =
          headingToFontSize[node.attributes.heading] ?? _baseFontSize;
      return TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600);
    },
    padding: (EditorState editorState, Node node) {
      final headingToPadding = {
        'h1': basePadding + 6,
        'h2': basePadding + 4,
        'h3': basePadding + 2,
        'h4': basePadding,
        'h5': basePadding,
        'h6': basePadding,
      };
      final padding = headingToPadding[node.attributes.heading] ?? basePadding;
      return EdgeInsets.only(bottom: padding);
    },
  );
  final pluginTheme = Theme.of(context).brightness == Brightness.dark
      ? darkPlguinStyleExtension
      : lightPlguinStyleExtension;
  return pluginTheme.toList()
    ..removeWhere((element) => element is HeadingPluginStyle)
    ..add(headingPluginStyle);
}
