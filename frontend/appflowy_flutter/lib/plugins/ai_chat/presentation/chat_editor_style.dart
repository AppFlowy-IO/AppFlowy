// ref appflowy_flutter/lib/plugins/document/presentation/editor_style.dart

// diff:
// - text style
// - heading text style and padding builders
// - don't listen to document appearance cubit
//

import 'package:appflowy/mobile/application/page_style/document_page_style_bloc.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_platform/universal_platform.dart';

class ChatEditorStyleCustomizer extends EditorStyleCustomizer {
  ChatEditorStyleCustomizer({
    required super.context,
    required super.padding,
    super.width,
  });

  @override
  EditorStyle desktop() {
    final theme = Theme.of(context);
    final afThemeExtension = AFThemeExtension.of(context);
    final appearanceFont = context.read<AppearanceSettingsCubit>().state.font;
    final appearance = context.read<DocumentAppearanceCubit>().state;
    const fontSize = 14.0;
    String fontFamily = appearance.fontFamily;
    if (fontFamily.isEmpty && appearanceFont.isNotEmpty) {
      fontFamily = appearanceFont;
    }

    return EditorStyle.desktop(
      padding: padding,
      maxWidth: width,
      cursorColor: appearance.cursorColor ??
          DefaultAppearanceSettings.getDefaultCursorColor(context),
      selectionColor: appearance.selectionColor ??
          DefaultAppearanceSettings.getDefaultSelectionColor(context),
      defaultTextDirection: appearance.defaultTextDirection,
      textStyleConfiguration: TextStyleConfiguration(
        lineHeight: 1.4,
        applyHeightToFirstAscent: true,
        applyHeightToLastDescent: true,
        text: baseTextStyle(fontFamily).copyWith(
          fontSize: fontSize,
          color: afThemeExtension.onBackground,
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
            fontSize: fontSize,
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

  @override
  TextStyle headingStyleBuilder(int level) {
    final String? fontFamily;
    final List<double> fontSizes;
    const fontSize = 14.0;

    fontFamily = context.read<DocumentAppearanceCubit>().state.fontFamily;
    fontSizes = [
      fontSize + 12,
      fontSize + 10,
      fontSize + 6,
      fontSize + 2,
      fontSize,
    ];
    return baseTextStyle(fontFamily, fontWeight: FontWeight.w600).copyWith(
      fontSize: fontSizes.elementAtOrNull(level - 1) ?? fontSize,
    );
  }

  @override
  CodeBlockStyle codeBlockStyleBuilder() {
    final fontFamily =
        context.read<DocumentAppearanceCubit>().state.codeFontFamily;

    return CodeBlockStyle(
      textStyle: baseTextStyle(fontFamily).copyWith(
        height: 1.4,
        color: AFThemeExtension.of(context).onBackground,
      ),
      backgroundColor: AFThemeExtension.of(context).calloutBGColor,
      foregroundColor: AFThemeExtension.of(context).textColor.withAlpha(155),
      wrapLines: true,
    );
  }

  @override
  TextStyle calloutBlockStyleBuilder() {
    if (UniversalPlatform.isMobile) {
      final afThemeExtension = AFThemeExtension.of(context);
      final pageStyle = context.read<DocumentPageStyleBloc>().state;
      final fontFamily = pageStyle.fontFamily ?? defaultFontFamily;
      final baseTextStyle = this.baseTextStyle(fontFamily);
      return baseTextStyle.copyWith(
        color: afThemeExtension.onBackground,
      );
    } else {
      final fontSize = context.read<DocumentAppearanceCubit>().state.fontSize;
      return baseTextStyle(null).copyWith(
        fontSize: fontSize,
        height: 1.5,
      );
    }
  }

  @override
  TextStyle outlineBlockPlaceholderStyleBuilder() {
    return TextStyle(
      fontFamily: defaultFontFamily,
      height: 1.5,
      color: AFThemeExtension.of(context).onBackground.withOpacity(0.6),
    );
  }
}
