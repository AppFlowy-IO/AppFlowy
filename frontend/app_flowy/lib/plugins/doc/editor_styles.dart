import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

EditorStyle customEditorTheme(BuildContext context) {
  final theme = context.watch<AppTheme>();
  const baseFontSize = 14.0;
  const basePadding = 12.0;

  var editorStyle = theme.isDark ? EditorStyle.dark : EditorStyle.light;
  editorStyle = editorStyle.copyWith(
    textStyle: editorStyle.textStyle?.copyWith(
      fontFamily: 'poppins',
      fontSize: baseFontSize,
    ),
    bold: editorStyle.bold?.copyWith(
      fontWeight: FontWeight.w500,
    ),
  );
  return editorStyle;
}

Iterable<ThemeExtension<dynamic>> customPluginTheme(BuildContext context) {
  final theme = context.watch<AppTheme>();

  return theme.isDark ? darkPlguinStyleExtension : lightPlguinStyleExtension;
}

//   return EditorStyle.defaultStyle().copyWith(
//     padding = const EdgeInsets.symmetric(horizontal: 80),
//     textStyle = textStyle,
//     pluginStyles = {
//       'text/heading': builtInPluginStyle
//         ..update(
//           'textStyle',
//           (_) => (EditorState editorState, Node node) {
//             final headingToFontSize = {
//               'h1': baseFontSize + 12,
//               'h2': baseFontSize + 8,
//               'h3': baseFontSize + 4,
//               'h4': baseFontSize,
//               'h5': baseFontSize,
//               'h6': baseFontSize,
//             };
//             final fontSize =
//                 headingToFontSize[node.attributes.heading] ?? baseFontSize;
//             return TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600);
//           },
//         )
//         ..update(
//           'padding',
//           (_) => (EditorState editorState, Node node) {
//             final headingToPadding = {
//               'h1': basePadding + 6,
//               'h2': basePadding + 4,
//               'h3': basePadding + 2,
//               'h4': basePadding,
//               'h5': basePadding,
//               'h6': basePadding,
//             };
//             final padding =
//                 headingToPadding[node.attributes.heading] ?? basePadding;
//             return EdgeInsets.only(bottom: padding);
//           },
//         ),
//       'text/number-list': builtInPluginStyle
//         ..addAll(
//           {
//             'numberColor': (EditorState editorState, Node node) {
//               final theme = context.watch<AppTheme>();
//               return theme.isDark ? Colors.white : Colors.black;
//             },
//           },
//         ),
//       'text/bulleted-list': builtInPluginStyle
//         ..addAll(
//           {
//             'bulletColor': (EditorState editorState, Node node) {
//               final theme = context.watch<AppTheme>();
//               return theme.isDark ? Colors.white : Colors.black;
//             },
//           },
//         ),
//     },
//   );
// }
