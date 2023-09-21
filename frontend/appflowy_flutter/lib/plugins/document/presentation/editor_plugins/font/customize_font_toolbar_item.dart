import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/font_family_setting.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';

final customizeFontToolbarItem = ToolbarItem(
  id: 'editor.font',
  group: 4,
  isActive: onlyShowInTextType,
  builder: (context, editorState, highlightColor) {
    final selection = editorState.selection!;
    final popoverController = PopoverController();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: FontFamilyDropDown(
        currentFontFamily: '',
        popoverController: popoverController,
        onOpen: () => keepEditorFocusNotifier.value += 1,
        onClose: () => keepEditorFocusNotifier.value -= 1,
        onFontFamilyChanged: (fontFamily) async {
          await popoverController.close();
          try {
            await editorState.formatDelta(selection, {
              AppFlowyRichTextKeys.fontFamily: fontFamily,
            });
          } catch (e) {
            Log.error('Failed to set font family: $e');
          }
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: FlowySvg(
            FlowySvgs.font_family_s,
            size: Size.square(16.0),
            color: Colors.white,
          ),
        ),
      ),
    );
  },
);
