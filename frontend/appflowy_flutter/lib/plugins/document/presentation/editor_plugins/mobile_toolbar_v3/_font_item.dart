import 'package:appflowy/mobile/presentation/setting/font/font_picker_screen.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FontFamilyItem extends StatelessWidget {
  const FontFamilyItem({
    super.key,
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget build(BuildContext context) {
    final fontFamily = editorState.getDeltaAttributeValueInSelection<String>(
      AppFlowyRichTextKeys.fontFamily,
    );
    final systemFonFamily =
        context.read<DocumentAppearanceCubit>().state.fontFamily;
    return MobileToolbarItemWrapper(
      size: const Size(144, 52),
      onTap: () async {
        final selection = editorState.selection;
        final newFont = await context
            .read<GoRouter>()
            .push<String>(FontPickerScreen.routeName);
        if (newFont != null && newFont != fontFamily) {
          await editorState.formatDelta(selection, {
            AppFlowyRichTextKeys.fontFamily:
                GoogleFonts.getFont(newFont).fontFamily,
          });
        }
      },
      text: fontFamily ?? systemFonFamily,
      fontFamily: fontFamily ?? systemFonFamily,
      backgroundColor: const Color(0xFFF2F2F7),
      isSelected: false,
      enable: editorState.selection?.isCollapsed == false,
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
}
