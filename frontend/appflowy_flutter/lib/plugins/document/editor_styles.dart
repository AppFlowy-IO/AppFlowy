import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

EditorStyle customEditorTheme(BuildContext context) {
  final documentStyle = context.watch<DocumentAppearanceCubit>().state;
  final theme = Theme.of(context);

  var editorStyle = EditorStyle(
    // Editor styles
    padding: const EdgeInsets.symmetric(horizontal: 100),
    backgroundColor: theme.colorScheme.surface,
    cursorColor: theme.colorScheme.primary,
    // Text styles
    textPadding: const EdgeInsets.symmetric(vertical: 8.0),
    textStyle: TextStyle(
      fontFamily: 'poppins',
      fontSize: documentStyle.fontSize,
      color: theme.colorScheme.onBackground,
    ),
    selectionColor: theme.colorScheme.tertiary.withOpacity(0.2),
    // Selection menu
    selectionMenuBackgroundColor: theme.cardColor,
    selectionMenuItemTextColor: theme.iconTheme.color,
    selectionMenuItemIconColor: theme.colorScheme.onBackground,
    selectionMenuItemSelectedIconColor: theme.colorScheme.onSurface,
    selectionMenuItemSelectedTextColor: theme.colorScheme.onSurface,
    selectionMenuItemSelectedColor: theme.hoverColor,
    // Toolbar and its item's style
    toolbarColor: theme.colorScheme.onTertiary,
    toolbarElevation: 0,
    lineHeight: 1.5,
    placeholderTextStyle:
        TextStyle(fontSize: documentStyle.fontSize, color: theme.hintColor),
    bold: const TextStyle(
      fontFamily: 'poppins-Bold',
      fontWeight: FontWeight.w600,
    ),
    italic: const TextStyle(fontStyle: FontStyle.italic),
    underline: const TextStyle(decoration: TextDecoration.underline),
    strikethrough: const TextStyle(decoration: TextDecoration.lineThrough),
    href: TextStyle(
      color: theme.colorScheme.primary,
      decoration: TextDecoration.underline,
    ),
    highlightColorHex: '0x6000BCF0',
    code: GoogleFonts.robotoMono(
      textStyle: TextStyle(
        fontSize: documentStyle.fontSize,
        fontWeight: FontWeight.normal,
        color: Colors.red,
        backgroundColor: theme.colorScheme.inverseSurface,
      ),
    ),
    popupMenuFGColor: theme.iconTheme.color,
    popupMenuHoverColor: theme.colorScheme.tertiaryContainer,
  );

  return editorStyle;
}

Iterable<ThemeExtension<dynamic>> customPluginTheme(BuildContext context) {
  final documentStyle = context.watch<DocumentAppearanceCubit>().state;
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
      ? darkPluginStyleExtension
      : lightPluginStyleExtension;
  return pluginTheme.toList()
    ..removeWhere(
      (element) =>
          element is HeadingPluginStyle || element is NumberListPluginStyle,
    )
    ..add(headingPluginStyle)
    ..add(numberListPluginStyle);
}
