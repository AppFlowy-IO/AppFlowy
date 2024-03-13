import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_color_list.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class ColorItem extends StatelessWidget {
  const ColorItem({
    super.key,
    required this.editorState,
    required this.service,
  });

  final EditorState editorState;
  final AppFlowyMobileToolbarWidgetService service;

  @override
  Widget build(BuildContext context) {
    final theme = ToolbarColorExtension.of(context);
    final selectedBackgroundColor = _getBackgroundColor(context);

    return MobileToolbarMenuItemWrapper(
      size: const Size(82, 52),
      onTap: () async {
        service.closeKeyboard();
        unawaited(
          editorState.updateSelectionWithReason(
            editorState.selection,
            extraInfo: {
              selectionExtraInfoDisableMobileToolbarKey: true,
              selectionExtraInfoDisableFloatingToolbar: true,
              selectionExtraInfoDoNotAttachTextService: true,
            },
          ),
        );
        keepEditorFocusNotifier.increase();
        await showTextColorAndBackgroundColorPicker(
          context,
          editorState: editorState,
          selection: editorState.selection!,
        );
      },
      icon: FlowySvgs.m_aa_color_s,
      backgroundColor:
          selectedBackgroundColor ?? theme.toolbarMenuItemBackgroundColor,
      selectedBackgroundColor: selectedBackgroundColor,
      isSelected: selectedBackgroundColor != null,
      showRightArrow: true,
      iconPadding: const EdgeInsets.only(
        top: 14.0,
        bottom: 14.0,
        right: 28.0,
      ),
    );
  }

  Color? _getBackgroundColor(BuildContext context) {
    final selection = editorState.selection;
    if (selection == null) {
      return null;
    }
    String? backgroundColor =
        editorState.toggledStyle[AppFlowyRichTextKeys.backgroundColor];
    if (backgroundColor == null) {
      if (selection.isCollapsed && selection.startIndex != 0) {
        backgroundColor = editorState.getDeltaAttributeValueInSelection<String>(
          AppFlowyRichTextKeys.backgroundColor,
          selection.copyWith(
            start: selection.start.copyWith(
              offset: selection.startIndex - 1,
            ),
          ),
        );
      } else {
        backgroundColor = editorState.getDeltaAttributeValueInSelection<String>(
          AppFlowyRichTextKeys.backgroundColor,
        );
      }
    }
    if (backgroundColor != null && int.tryParse(backgroundColor) != null) {
      return Color(int.parse(backgroundColor));
    }
    return null;
  }
}
