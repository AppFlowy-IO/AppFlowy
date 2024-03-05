import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_item/utils.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/util/google_font_family_extension.dart';
import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:collection/collection.dart';
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
    final appearance = context.read<DocumentAppearanceCubit>().state;
    final fontSize = appearance.fontSize;
    final fontFamily = appearance.fontFamily;

    return EditorStyle.desktop(
      padding: padding,
      cursorColor: appearance.cursorColor ??
          DefaultAppearanceSettings.getDefaultDocumentCursorColor(context),
      selectionColor: appearance.selectionColor ??
          DefaultAppearanceSettings.getDefaultDocumentSelectionColor(context),
      defaultTextDirection: appearance.defaultTextDirection,
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
            fontSize: fontSize - 2,
            fontWeight: FontWeight.normal,
            color: Colors.red,
            backgroundColor: theme.colorScheme.inverseSurface.withOpacity(0.8),
          ),
        ),
      ),
      textSpanDecorator: customizeAttributeDecorator,
      textScaleFactor:
          context.watch<AppearanceSettingsCubit>().state.textScaleFactor,
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
      mobileDragHandleBallSize: const Size.square(12.0),
      magnifierSize: const Size(144, 96),
      textScaleFactor:
          context.watch<AppearanceSettingsCubit>().state.textScaleFactor,
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
              MentionType.date => mention[MentionBlockKeys.date],
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
    final formula = attributes[InlineMathEquationKeys.formula];
    if (formula is String) {
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
            final editorState = context.read<EditorState>();
            if (editorState.selection == null) {
              afLaunchUrlString(href);
              return;
            }

            editorState.updateSelectionWithReason(
              editorState.selection,
              extraInfo: {
                selectionExtraInfoDisableMobileToolbarKey: true,
              },
            );

            showEditLinkBottomSheet(
              context,
              text.text,
              href,
              (linkContext, newText, newHref) {
                final selection = Selection.single(
                  path: node.path,
                  startOffset: index,
                  endOffset: index + text.text.length,
                );
                editorState.updateTextAndHref(
                  text.text,
                  href,
                  newText,
                  newHref,
                  selection: selection,
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
}
