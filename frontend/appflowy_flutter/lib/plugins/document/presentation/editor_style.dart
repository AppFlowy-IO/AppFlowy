import 'dart:math';

import 'package:appflowy/plugins/document/presentation/editor_plugins/inline_math_equation/inline_math_equation.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_item/utils.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/util/google_font_family_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EditorStyleCustomizer {
  EditorStyleCustomizer({
    required this.context,
    required this.padding,
  });

  final BuildContext context;
  final EdgeInsets padding;

  EditorStyle style() {
    if (PlatformExtension.isDesktopOrWeb) {
      return desktop();
    } else if (PlatformExtension.isMobile) {
      return mobile();
    }
    throw UnimplementedError();
  }

  static EdgeInsets get documentPadding => PlatformExtension.isMobile
      ? const EdgeInsets.only(left: 20, right: 20)
      : const EdgeInsets.only(left: 40, right: 40 + 44);

  EditorStyle desktop() {
    final theme = Theme.of(context);
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    final fontFamily = context.read<DocumentAppearanceCubit>().state.fontFamily;
    final defaultTextDirection =
        context.read<DocumentAppearanceCubit>().state.defaultTextDirection;
    final codeFontSize = max(0.0, fontSize - 2);
    return EditorStyle.desktop(
      padding: padding,
      cursorColor: theme.colorScheme.primary,
      defaultTextDirection: defaultTextDirection,
      textStyleConfiguration: TextStyleConfiguration(
        text: baseTextStyle(fontFamily).copyWith(
          fontSize: fontSize,
          color: theme.colorScheme.onBackground,
          height: 1.5,
        ),
        bold: baseTextStyle(fontFamily, fontWeight: FontWeight.bold).copyWith(
          fontWeight: FontWeight.w600,
        ),
        italic: baseTextStyle(fontFamily).copyWith(
          fontStyle: FontStyle.italic,
        ),
        underline: baseTextStyle(fontFamily).copyWith(
          decoration: TextDecoration.underline,
        ),
        strikethrough: baseTextStyle(fontFamily).copyWith(
          decoration: TextDecoration.lineThrough,
        ),
        href: baseTextStyle(fontFamily).copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: GoogleFonts.robotoMono(
          textStyle: baseTextStyle(fontFamily).copyWith(
            fontSize: codeFontSize,
            fontWeight: FontWeight.normal,
            fontStyle: FontStyle.italic,
            color: Colors.red,
            backgroundColor: theme.colorScheme.inverseSurface.withOpacity(0.8),
          ),
        ),
      ),
      textSpanDecorator: customizeAttributeDecorator,
    );
  }

  EditorStyle mobile() {
    final theme = Theme.of(context);
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    final fontFamily = context.read<DocumentAppearanceCubit>().state.fontFamily;
    final defaultTextDirection =
        context.read<DocumentAppearanceCubit>().state.defaultTextDirection;
    final codeFontSize = max(0.0, fontSize - 2);
    return EditorStyle.mobile(
      padding: padding,
      defaultTextDirection: defaultTextDirection,
      textStyleConfiguration: TextStyleConfiguration(
        text: baseTextStyle(fontFamily).copyWith(
          fontSize: fontSize,
          color: theme.colorScheme.onBackground,
          height: 1.5,
        ),
        bold: baseTextStyle(fontFamily, fontWeight: FontWeight.bold).copyWith(
          fontWeight: FontWeight.w600,
        ),
        italic: baseTextStyle(fontFamily).copyWith(
          fontStyle: FontStyle.italic,
        ),
        underline: baseTextStyle(fontFamily).copyWith(
          decoration: TextDecoration.underline,
        ),
        strikethrough: baseTextStyle(fontFamily).copyWith(
          decoration: TextDecoration.lineThrough,
        ),
        href: baseTextStyle(fontFamily).copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: GoogleFonts.robotoMono(
          textStyle: baseTextStyle(fontFamily).copyWith(
            fontSize: codeFontSize,
            fontWeight: FontWeight.normal,
            fontStyle: FontStyle.italic,
            color: Colors.red,
            backgroundColor: Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
      textSpanDecorator: customizeAttributeDecorator,
    );
  }

  TextStyle headingStyleBuilder(int level) {
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    final fontSizes = [
      fontSize + 16,
      fontSize + 12,
      fontSize + 8,
      fontSize + 4,
      fontSize + 2,
      fontSize,
    ];
    final fontFamily = context.read<DocumentAppearanceCubit>().state.fontFamily;
    return baseTextStyle(fontFamily, fontWeight: FontWeight.bold).copyWith(
      fontWeight: FontWeight.w600,
      fontSize: fontSizes.elementAtOrNull(level - 1) ?? fontSize,
    );
  }

  TextStyle codeBlockStyleBuilder() {
    final theme = Theme.of(context);
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    final fontFamily = context.read<DocumentAppearanceCubit>().state.fontFamily;
    return baseTextStyle(fontFamily).copyWith(
      fontSize: fontSize,
      height: 1.5,
      color: theme.colorScheme.onBackground,
    );
  }

  TextStyle outlineBlockPlaceholderStyleBuilder() {
    final theme = Theme.of(context);
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    return TextStyle(
      fontFamily: builtInFontFamily,
      fontSize: fontSize,
      height: 1.5,
      color: theme.colorScheme.onBackground.withOpacity(0.6),
    );
  }

  SelectionMenuStyle selectionMenuStyleBuilder() {
    final theme = Theme.of(context);
    return SelectionMenuStyle(
      selectionMenuBackgroundColor: theme.cardColor,
      selectionMenuItemTextColor: theme.colorScheme.onBackground,
      selectionMenuItemIconColor: theme.colorScheme.onBackground,
      selectionMenuItemSelectedIconColor: theme.colorScheme.onSurface,
      selectionMenuItemSelectedTextColor: theme.colorScheme.onSurface,
      selectionMenuItemSelectedColor: theme.hoverColor,
    );
  }

  InlineActionsMenuStyle inlineActionsMenuStyleBuilder() {
    final theme = Theme.of(context);
    return InlineActionsMenuStyle(
      backgroundColor: theme.cardColor,
      groupTextColor: theme.colorScheme.onBackground.withOpacity(.8),
      menuItemTextColor: theme.colorScheme.onBackground,
      menuItemSelectedColor: theme.colorScheme.secondary,
      menuItemSelectedTextColor: theme.colorScheme.onSurface,
    );
  }

  FloatingToolbarStyle floatingToolbarStyleBuilder() {
    final theme = Theme.of(context);
    return FloatingToolbarStyle(
      backgroundColor: theme.colorScheme.onTertiary,
    );
  }

  TextStyle baseTextStyle(
    String fontFamily, {
    FontWeight? fontWeight,
  }) {
    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontWeight: fontWeight,
      );
    } on Exception {
      return GoogleFonts.getFont(builtInFontFamily);
    }
  }

  InlineSpan customizeAttributeDecorator(
    BuildContext context,
    Node node,
    int index,
    TextInsert text,
    TextSpan before,
    TextSpan after,
  ) {
    final attributes = text.attributes;
    if (attributes == null) {
      return before;
    }

    // try to refresh font here.
    if (attributes.fontFamily != null) {
      try {
        GoogleFonts.getFont(attributes.fontFamily!.parseFontFamilyName());
      } catch (e) {
        // ignore
      }
    }

    // Inline Mentions (Page Reference, Date, Reminder, etc.)
    final mention =
        attributes[MentionBlockKeys.mention] as Map<String, dynamic>?;
    if (mention != null) {
      final type = mention[MentionBlockKeys.type];
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        style: after.style,
        child: MentionBlock(
          key: ValueKey(
            switch (type) {
              MentionType.page => mention[MentionBlockKeys.pageId],
              MentionType.date ||
              MentionType.reminder =>
                mention[MentionBlockKeys.date],
              _ => MentionBlockKeys.mention,
            },
          ),
          node: node,
          index: index,
          mention: mention,
          textStyle: after.style,
        ),
      );
    }

    // customize the inline math equation block
    final formula = attributes[InlineMathEquationKeys.formula] as String?;
    if (formula != null) {
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: InlineMathEquation(
          node: node,
          index: index,
          formula: formula,
          textStyle: style().textStyleConfiguration.text,
        ),
      );
    }

    // customize the link on mobile
    final href = attributes[AppFlowyRichTextKeys.href] as String?;
    if (PlatformExtension.isMobile && href != null) {
      return TextSpan(
        style: before.style,
        text: text.text,
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            showEditLinkBottomSheet(
              context,
              text.text,
              href,
              (linkContext, newText, newHref) {
                _updateTextAndHref(
                  context,
                  node,
                  index,
                  text.text,
                  href,
                  newText,
                  newHref,
                );
                linkContext.pop();
              },
            );
          },
      );
    }

    return defaultTextSpanDecoratorForAttribute(
      context,
      node,
      index,
      text,
      before,
      after,
    );
  }

  void _updateTextAndHref(
    BuildContext context,
    Node node,
    int index,
    String prevText,
    String? prevHref,
    String text,
    String href,
  ) async {
    final selection = Selection.single(
      path: node.path,
      startOffset: index,
      endOffset: index + prevText.length,
    );
    final editorState = context.read<EditorState>();
    final transaction = editorState.transaction;
    if (prevText != text) {
      transaction.replaceText(
        node,
        selection.startIndex,
        selection.length,
        text,
      );
    }
    // if the text is empty, it means the user wants to remove the text
    if (text.isNotEmpty && prevHref != href) {
      transaction.formatText(node, selection.startIndex, text.length, {
        AppFlowyRichTextKeys.href: href.isEmpty ? null : href,
      });
    }
    await editorState.apply(transaction);
  }
}
