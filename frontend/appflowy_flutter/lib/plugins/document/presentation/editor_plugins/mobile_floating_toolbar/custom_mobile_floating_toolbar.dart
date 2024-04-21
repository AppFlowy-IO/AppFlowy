import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

List<ContextMenuButtonItem> buildMobileFloatingToolbarItems(
  EditorState editorState,
  Offset offset,
  Function closeToolbar,
) {
  // copy, paste, select, select all, cut
  final selection = editorState.selection;
  if (selection == null) {
    return [];
  }
  final toolbarItems = <ContextMenuButtonItem>[];

  if (!selection.isCollapsed) {
    toolbarItems.add(
      ContextMenuButtonItem(
        label: LocaleKeys.editor_copy.tr(),
        onPressed: () {
          copyCommand.execute(editorState);
          closeToolbar();
        },
      ),
    );
  }

  toolbarItems.add(
    ContextMenuButtonItem(
      label: LocaleKeys.editor_paste.tr(),
      onPressed: () {
        pasteCommand.execute(editorState);
        closeToolbar();
      },
    ),
  );

  if (!selection.isCollapsed) {
    toolbarItems.add(
      ContextMenuButtonItem(
        label: LocaleKeys.editor_cut.tr(),
        onPressed: () {
          cutCommand.execute(editorState);
          closeToolbar();
        },
      ),
    );
  }

  toolbarItems.add(
    ContextMenuButtonItem(
      label: LocaleKeys.editor_select.tr(),
      onPressed: () {
        editorState.selectWord(offset);
        closeToolbar();
      },
    ),
  );

  toolbarItems.add(
    ContextMenuButtonItem(
      label: LocaleKeys.editor_selectAll.tr(),
      onPressed: () {
        selectAllCommand.execute(editorState);
        closeToolbar();
      },
    ),
  );

  return toolbarItems;
}

extension on EditorState {
  void selectWord(Offset offset) {
    final node = service.selectionService.getNodeInOffset(offset);
    final selection = node?.selectable?.getWordBoundaryInOffset(offset);
    if (selection == null) {
      return;
    }
    updateSelectionWithReason(selection);
  }
}

class CustomMobileFloatingToolbar extends StatelessWidget {
  const CustomMobileFloatingToolbar({
    super.key,
    required this.editorState,
    required this.anchor,
    required this.closeToolbar,
  });

  final EditorState editorState;
  final Offset anchor;
  final VoidCallback closeToolbar;

  @override
  Widget build(BuildContext context) {
    return Animate(
      autoPlay: true,
      effects: [
        const FadeEffect(duration: SelectionOverlay.fadeDuration),
        MoveEffect(
          curve: Curves.easeOutCubic,
          begin: const Offset(0, 16),
          duration: 100.milliseconds,
        ),
      ],
      child: AdaptiveTextSelectionToolbar.buttonItems(
        buttonItems: buildMobileFloatingToolbarItems(
          editorState,
          anchor,
          closeToolbar,
        ),
        anchors: TextSelectionToolbarAnchors(
          primaryAnchor: anchor,
        ),
      ),
    );
  }
}
