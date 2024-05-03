import 'dart:async';

import 'package:appflowy/mobile/presentation/setting/font/font_picker_screen.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/shared/google_fonts_extension.dart';
import 'package:appflowy/util/google_font_family_extension.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FontFamilyItem extends StatelessWidget {
  const FontFamilyItem({
    super.key,
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    final theme = ToolbarColorExtension.of(context);
    final fontFamily = _getCurrentSelectedFontFamilyName();
    final systemFonFamily =
        context.read<DocumentAppearanceCubit>().state.fontFamily;
    return MobileToolbarMenuItemWrapper(
      size: const Size(144, 52),
      onTap: () async {
        final selection = editorState.selection;
        if (selection == null) {
          return;
        }
        // disable the floating toolbar
        unawaited(
          editorState.updateSelectionWithReason(
            selection,
            extraInfo: {
              selectionExtraInfoDisableFloatingToolbar: true,
              selectionExtraInfoDisableMobileToolbarKey: true,
            },
          ),
        );

        final newFont = await context
            .read<GoRouter>()
            .push<String>(FontPickerScreen.routeName);

        // if the selection is not collapsed, apply the font to the selection.
        if (newFont != null && !selection.isCollapsed) {
          if (newFont != fontFamily) {
            await editorState.formatDelta(selection, {
              AppFlowyRichTextKeys.fontFamily: newFont,
            });
          }
        }

        // wait for the font picker screen to be dismissed.
        Future.delayed(const Duration(milliseconds: 250), () {
          // highlight the selected text again.
          editorState.updateSelectionWithReason(
            selection,
            extraInfo: {
              selectionExtraInfoDisableFloatingToolbar: true,
              selectionExtraInfoDisableMobileToolbarKey: false,
            },
          );
          // if the selection is collapsed, save the font for the next typing.
          if (newFont != null && selection.isCollapsed) {
            editorState.updateToggledStyle(
              AppFlowyRichTextKeys.fontFamily,
              getGoogleFontSafely(newFont).fontFamily,
            );
          }
        });
      },
      text: (fontFamily ?? systemFonFamily).parseFontFamilyName(),
      fontFamily: fontFamily ?? systemFonFamily,
      backgroundColor: theme.toolbarMenuItemBackgroundColor,
      isSelected: false,
      enable: true,
      showRightArrow: true,
      iconPadding: const EdgeInsets.only(
        top: 14.0,
        bottom: 14.0,
        left: 14.0,
        right: 12.0,
      ),
      textPadding: const EdgeInsets.only(
        right: 16.0,
      ),
    );
  }

  String? _getCurrentSelectedFontFamilyName() {
    final toggleFontFamily =
        editorState.toggledStyle[AppFlowyRichTextKeys.fontFamily];
    if (toggleFontFamily is String && toggleFontFamily.isNotEmpty) {
      return toggleFontFamily;
    }
    final selection = editorState.selection;
    if (selection != null &&
        selection.isCollapsed &&
        selection.startIndex != 0) {
      return editorState.getDeltaAttributeValueInSelection<String>(
        AppFlowyRichTextKeys.fontFamily,
        selection.copyWith(
          start: selection.start.copyWith(
            offset: selection.startIndex - 1,
          ),
        ),
      );
    }
    return editorState.getDeltaAttributeValueInSelection<String>(
      AppFlowyRichTextKeys.fontFamily,
    );
  }
}
