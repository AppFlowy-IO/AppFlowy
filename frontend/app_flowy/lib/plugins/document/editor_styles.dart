import 'package:app_flowy/plugins/document/document.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

EditorStyle customEditorTheme(BuildContext context) {
  final documentStyle = context.watch<DocumentStyle>();
  var editorStyle = Theme.of(context).brightness == Brightness.dark
      ? EditorStyle.dark
      : EditorStyle.light;
  editorStyle = editorStyle.copyWith(
    padding: const EdgeInsets.all(0),
    textStyle: editorStyle.textStyle?.copyWith(
      fontFamily: 'poppins',
      fontSize: documentStyle.fontSize,
    ),
    placeholderTextStyle: editorStyle.placeholderTextStyle?.copyWith(
      fontFamily: 'poppins',
      fontSize: documentStyle.fontSize,
    ),
    bold: editorStyle.bold?.copyWith(
      fontWeight: FontWeight.w500,
    ),
    backgroundColor: Theme.of(context).colorScheme.surface,
  );
  return editorStyle;
}

Iterable<ThemeExtension<dynamic>> customPluginTheme(BuildContext context) {
  final documentStyle = context.watch<DocumentStyle>();
  final baseFontSize = documentStyle.fontSize;
  const basePadding = 12.0;
  var headingPluginStyle = Theme.of(context).brightness == Brightness.dark
      ? HeadingPluginStyle.dark
      : HeadingPluginStyle.light;
  headingPluginStyle = headingPluginStyle.copyWith(
    textStyle: (EditorState editorState, Node node) {
      final headingToFontSize = {
        'h1': baseFontSize + 12,
        'h2': baseFontSize + 8,
        'h3': baseFontSize + 4,
        'h4': baseFontSize,
        'h5': baseFontSize,
        'h6': baseFontSize,
      };
      final fontSize =
          headingToFontSize[node.attributes.heading] ?? baseFontSize;
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
  var numberListPluginStyle = Theme.of(context).brightness == Brightness.dark
      ? NumberListPluginStyle.dark
      : NumberListPluginStyle.light;

  numberListPluginStyle = numberListPluginStyle.copyWith(
    icon: (_, textNode) {
      const iconPadding = EdgeInsets.only(left: 5.0, right: 5.0);
      return Container(
        padding: iconPadding,
        child: Text(
          '${textNode.attributes.number.toString()}.',
          style: customEditorTheme(context).textStyle,
        ),
      );
    },
  );
  final pluginTheme = Theme.of(context).brightness == Brightness.dark
      ? darkPlguinStyleExtension
      : lightPlguinStyleExtension;
  return pluginTheme.toList()
    ..removeWhere((element) =>
        element is HeadingPluginStyle || element is NumberListPluginStyle)
    ..add(headingPluginStyle)
    ..add(numberListPluginStyle);
}
