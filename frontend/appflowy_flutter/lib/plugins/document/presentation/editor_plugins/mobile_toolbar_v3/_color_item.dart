import 'dart:async';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_color_list.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/_toolbar_theme.dart';
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
      backgroundColor: theme.toolbarMenuItemBackgroundColor,
      isSelected: false,
      showRightArrow: true,
      enable: editorState.selection?.isCollapsed == false,
      iconPadding: const EdgeInsets.only(
        top: 14.0,
        bottom: 14.0,
        right: 28.0,
      ),
    );
  }
}
