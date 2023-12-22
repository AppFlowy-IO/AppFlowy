import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

final undoToolbarItem = AppFlowyMobileToolbarItem(
  pilotAtCollapsedSelection: true,
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      iconBuilder: (context) {
        final canUndo = editorState.undoManager.undoStack.isNonEmpty;
        return FlowySvg(
          FlowySvgs.m_toolbar_undo_s,
          color: canUndo ? null : const Color(0xFFC7C7CC),
        );
      },
      onTap: () => undoCommand.execute(editorState),
    );
  },
);

final redoToolbarItem = AppFlowyMobileToolbarItem(
  itemBuilder: (context, editorState, _, __, onAction) {
    return AppFlowyMobileToolbarIconItem(
      iconBuilder: (context) {
        final canRedo = editorState.undoManager.redoStack.isNonEmpty;
        return FlowySvg(
          FlowySvgs.m_toolbar_redo_s,
          color: canRedo ? null : const Color(0xFFC7C7CC),
        );
      },
      onTap: () => redoCommand.execute(editorState),
    );
  },
);
