import 'package:appflowy/plugins/document/presentation/editor_plugins/inline_math_equation/inline_math_equation.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/inline_page/inline_page_reference.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  EditorStyle desktop() {
    final theme = Theme.of(context);
    final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
    final fontFamily = context.read<DocumentAppearanceCubit>().state.fontFamily;
    return EditorStyle.desktop(
      padding: padding,
      cursorColor: theme.colorScheme.primary,
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
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            color: Colors.red,
            backgroundColor: theme.colorScheme.inverseSurface,
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

    return EditorStyle.desktop(
      padding: padding,
      cursorColor: theme.colorScheme.primary,
      textStyleConfiguration: TextStyleConfiguration(
        text: baseTextStyle(fontFamily).copyWith(
          fontSize: fontSize,
          color: theme.colorScheme.onBackground,
          height: 1.5,
        ),
        bold: baseTextStyle(fontFamily).copyWith(
          fontWeight: FontWeight.w600,
        ),
        italic: baseTextStyle(fontFamily).copyWith(fontStyle: FontStyle.italic),
        underline: baseTextStyle(fontFamily)
            .copyWith(decoration: TextDecoration.underline),
        strikethrough: baseTextStyle(fontFamily)
            .copyWith(decoration: TextDecoration.lineThrough),
        href: baseTextStyle(fontFamily).copyWith(
          color: theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: GoogleFonts.robotoMono(
          textStyle: baseTextStyle(fontFamily).copyWith(
            fontSize: fontSize,
            fontWeight: FontWeight.normal,
            color: Colors.red,
            backgroundColor: theme.colorScheme.inverseSurface,
          ),
        ),
      ),
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
      fontSize
    ];
    return TextStyle(
      fontSize: fontSizes.elementAtOrNull(level - 1) ?? fontSize,
      fontWeight: FontWeight.bold,
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
      fontFamily: 'poppins',
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
      return GoogleFonts.getFont('Poppins');
    }
  }

  InlineSpan customizeAttributeDecorator(
    BuildContext context,
    Node node,
    int index,
    TextInsert text,
    TextSpan textSpan,
  ) {
    final attributes = text.attributes;
    if (attributes == null) {
      return textSpan;
    }

    // customize the inline mention block, like inline page
    final mention = attributes[MentionBlockKeys.mention] as Map?;
    if (mention != null) {
      final type = mention[MentionBlockKeys.type];
      if (type == MentionType.page.name) {
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: MentionBlock(
            key: ValueKey(mention[MentionBlockKeys.pageId]),
            mention: mention,
          ),
        );
      }
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

    return defaultTextSpanDecoratorForAttribute(
      context,
      node,
      index,
      text,
      textSpan,
    );
  }
}
