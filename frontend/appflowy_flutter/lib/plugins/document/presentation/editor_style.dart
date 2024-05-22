import 'dart:math';

import 'package:appflowy/core/helpers/url_launcher.dart';
import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/font_colors.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_item/utils.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/shared/google_fonts_extension.dart';
import 'package:appflowy/util/font_family_extension.dart';
import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class EditorStyleCustomizer {
  EditorStyleCustomizer({required this.context, required this.padding});

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
      ? const EdgeInsets.only(left: 24, right: 24)
      : const EdgeInsets.only(left: 40, right: 40 + 44);

  EditorStyle desktop() {
    final theme = Theme.of(context);
    final appearanceFont = context.read<AppearanceSettingsCubit>().state.font;
    final appearance = context.read<DocumentAppearanceCubit>().state;
    final fontSize = appearance.fontSize;
    String fontFamily = appearance.fontFamily;
    if (fontFamily.isEmpty && appearanceFont.isNotEmpty) {
      fontFamily = appearanceFont;
    }

    return EditorStyle.desktop(
      padding: padding,
      cursorColor: appearance.cursorColor ??
          DefaultAppearanceSettings.getDefaultCursorColor(context),
      selectionColor: appearance.selectionColor ??
          DefaultAppearanceSettings.getDefaultSelectionColor(context),
      defaultTextDirection: appearance.defaultTextDirection,
      textStyleConfiguration: TextStyleConfiguration(
        text: baseTextStyle(fontFamily).copyWith(
          fontSize: fontSize,
          color: theme.colorScheme.onSurface,
          height: 1.5,
        ),
        bold: baseTextStyle(fontFamily, fontWeight: FontWeight.bold).copyWith(
          fontWeight: FontWeight.w600,
        ),
        italic: baseTextStyle(fontFamily).copyWith(fontStyle: FontStyle.italic),
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
    final pageStyle = context.read<DocumentPageStyleBloc>().state;
    final theme = Theme.of(context);
    final fontSize = pageStyle.fontLayout.fontSize;
    final lineHeight = pageStyle.lineHeightLayout.lineHeight;
    final fontFamily = pageStyle.fontFamily ?? defaultFontFamily;
    final defaultTextDirection =
        context.read<DocumentAppearanceCubit>().state.defaultTextDirection;
    final textScaleFactor =
        context.read<AppearanceSettingsCubit>().state.textScaleFactor;
    final baseTextStyle = this.baseTextStyle(fontFamily);
    final codeFontSize = max(0.0, fontSize - 2);
    return EditorStyle.mobile(
      padding: padding,
      defaultTextDirection: defaultTextDirection,
      textStyleConfiguration: TextStyleConfiguration(
        text: baseTextStyle.copyWith(
          fontSize: fontSize,
          color: theme.colorScheme.onSurface,
          height: lineHeight,
        ),
        bold: baseTextStyle.copyWith(fontWeight: FontWeight.w600),
        italic: baseTextStyle.copyWith(fontStyle: FontStyle.italic),
        underline: baseTextStyle.copyWith(decoration: TextDecoration.underline),
        strikethrough: baseTextStyle.copyWith(
          decoration: TextDecoration.lineThrough,
        ),
        href: baseTextStyle.copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: GoogleFonts.robotoMono(
          textStyle: baseTextStyle.copyWith(
            fontSize: codeFontSize,
            fontWeight: FontWeight.normal,
            fontStyle: FontStyle.italic,
            color: Colors.red,
            backgroundColor: Colors.grey.withOpacity(0.3),
          ),
        ),
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: true,
      ),
      textSpanDecorator: customizeAttributeDecorator,
      mobileDragHandleBallSize: const Size.square(12.0),
      magnifierSize: const Size(144, 96),
      textScaleFactor: textScaleFactor,
    );
  }

  TextStyle headingStyleBuilder(int level) {
    final String? fontFamily;
    final List<double> fontSizes;
    final double fontSize;
    final FontWeight fontWeight =
        level <= 2 ? FontWeight.w700 : FontWeight.w600;
    if (PlatformExtension.isMobile) {
      final state = context.read<DocumentPageStyleBloc>().state;
      fontFamily = state.fontFamily;
      fontSize = state.fontLayout.fontSize;
      fontSizes = state.fontLayout.headingFontSizes;
    } else {
      fontFamily = context.read<DocumentAppearanceCubit>().state.fontFamily;
      fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
      fontSizes = [
        fontSize + 16,
        fontSize + 12,
        fontSize + 8,
        fontSize + 4,
        fontSize + 2,
        fontSize,
      ];
    }
    return baseTextStyle(fontFamily, fontWeight: fontWeight).copyWith(
      fontSize: fontSizes.elementAtOrNull(level - 1) ?? fontSize,
    );
  }

  TextStyle codeBlockStyleBuilder() {
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    final fontFamily =
        context.read<DocumentAppearanceCubit>().state.codeFontFamily;
    return baseTextStyle(fontFamily).copyWith(
      fontSize: fontSize,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  TextStyle outlineBlockPlaceholderStyleBuilder() {
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    return TextStyle(
      fontFamily: defaultFontFamily,
      fontSize: fontSize,
      height: 1.5,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );
  }

  SelectionMenuStyle selectionMenuStyleBuilder() {
    final theme = Theme.of(context);
    return SelectionMenuStyle(
      selectionMenuBackgroundColor: theme.cardColor,
      selectionMenuItemTextColor: theme.colorScheme.onSurface,
      selectionMenuItemIconColor: theme.colorScheme.onSurface,
      selectionMenuItemSelectedIconColor: theme.colorScheme.onSurface,
      selectionMenuItemSelectedTextColor: theme.colorScheme.onSurface,
      selectionMenuItemSelectedColor: theme.hoverColor,
    );
  }

  InlineActionsMenuStyle inlineActionsMenuStyleBuilder() {
    final theme = Theme.of(context);
    return InlineActionsMenuStyle(
      backgroundColor: theme.cardColor,
      groupTextColor: theme.colorScheme.onSurface.withOpacity(.8),
      menuItemTextColor: theme.colorScheme.onSurface,
      menuItemSelectedColor: theme.colorScheme.secondary,
      menuItemSelectedTextColor: theme.colorScheme.onSurface,
    );
  }

  FloatingToolbarStyle floatingToolbarStyleBuilder() => FloatingToolbarStyle(
        backgroundColor: Theme.of(context).colorScheme.onTertiary,
      );

  TextStyle baseTextStyle(String? fontFamily, {FontWeight? fontWeight}) {
    if (fontFamily == null || fontFamily == defaultFontFamily) {
      return TextStyle(fontWeight: fontWeight);
    }
    try {
      return getGoogleFontSafely(fontFamily, fontWeight: fontWeight);
    } on Exception {
      if ([defaultFontFamily, fallbackFontFamily, builtInCodeFontFamily]
          .contains(fontFamily)) {
        return TextStyle(fontFamily: fontFamily, fontWeight: fontWeight);
      }

      return TextStyle(fontWeight: fontWeight);
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

    if (attributes.backgroundColor != null) {
      final color = EditorFontColors.fromBuiltInColors(
        context,
        attributes.backgroundColor!,
      );
      if (color != null) {
        return TextSpan(
          text: before.text,
          style: after.style?.merge(
            TextStyle(backgroundColor: color),
          ),
        );
      }
    }

    // try to refresh font here.
    if (attributes.fontFamily != null) {
      try {
        if (before.text?.contains('_regular') == true) {
          getGoogleFontSafely(attributes.fontFamily!.parseFontFamilyName());
        } else {
          return TextSpan(
            text: before.text,
            style: after.style?.merge(
              getGoogleFontSafely(attributes.fontFamily!),
            ),
          );
        }
      } catch (_) {
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
              afLaunchUrlString(href, addingHttpSchemeWhenFailed: true);
              return;
            }

            editorState.updateSelectionWithReason(
              editorState.selection,
              extraInfo: {selectionExtraInfoDisableMobileToolbarKey: true},
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
