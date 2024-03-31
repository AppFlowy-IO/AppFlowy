import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_toolbar_theme.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/widgets.dart';

final undoToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    final theme = ToolbarColorExtension.of(context);
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      iconBuilder: (context) {
        final canUndo = editorState.undoManager.undoStack.isNonEmpty;
        return Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
          ),
          child: FlowySvg(
            FlowySvgs.m_toolbar_undo_m,
            color: canUndo
                ? theme.toolbarItemIconColor
                : theme.toolbarItemIconDisabledColor,
          ),
        );
      },
      onTap: () => undoCommand.execute(editorState),
    );
  },
);

final redoToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    final theme = ToolbarColorExtension.of(context);
    return AppFlowyMobileToolbarIconItem(
      editorState: editorState,
      iconBuilder: (context) {
        final canRedo = editorState.undoManager.redoStack.isNonEmpty;
        return Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
          ),
          child: FlowySvg(
            FlowySvgs.m_toolbar_redo_m,
            color: canRedo
                ? theme.toolbarItemIconColor
                : theme.toolbarItemIconDisabledColor,
          ),
        );
      },
      onTap: () => redoCommand.execute(editorState),
    );
  },
);
