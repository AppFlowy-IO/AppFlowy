import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/presentation/editor_drop_manager.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_file.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_image.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/shared/patterns/file_type_patterns.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:provider/provider.dart';

const _excludeFromDropTarget = [
  ImageBlockKeys.type,
  CustomImageBlockKeys.type,
  MultiImageBlockKeys.type,
  FileBlockKeys.type,
];

class EditorDropHandler extends StatelessWidget {
  const EditorDropHandler({
    super.key,
    required this.viewId,
    required this.editorState,
    required this.isLocalMode,
    required this.child,
    this.dropManagerState,
  });

  final String viewId;
  final EditorState editorState;
  final bool isLocalMode;
  final Widget child;
  final EditorDropManagerState? dropManagerState;

  @override
  Widget build(BuildContext context) {
    final childWidget = Consumer<EditorDropManagerState>(
      builder: (context, dropState, _) => DropTarget(
        enable: dropState.isDropEnabled,
        onDragExited: (_) => editorState.selectionService.removeDropTarget(),
        onDragUpdated: _onDragUpdated,
        onDragDone: _onDragDone,
        child: child,
      ),
    );

    // Due to how DropTarget works, there is no way to differentiate if an overlay is
    // blocking the target visibly, so when we have an overlay with a drop target,
    // we should disable the drop target for the Editor, until it is closed.
    //
    // See FileBlockComponent for sample use.
    //
    // Relates to:
    // - https://github.com/MixinNetwork/flutter-plugins/issues/2
    // - https://github.com/MixinNetwork/flutter-plugins/issues/331
    if (dropManagerState != null) {
      return ChangeNotifierProvider.value(
        value: dropManagerState!,
        child: childWidget,
      );
    }

    return ChangeNotifierProvider(
      create: (_) => EditorDropManagerState(),
      child: childWidget,
    );
  }

  void _onDragUpdated(DropEventDetails details) {
    final data = editorState.selectionService
        .getDropTargetRenderData(details.globalPosition);

    if (data != null &&
        data.dropPath != null &&

        // We implement custom Drop logic for image blocks, this is
        // how we can exclude them from the Drop Target
        !_excludeFromDropTarget.contains(data.cursorNode?.type)) {
      // Render the drop target
      editorState.selectionService
          .renderDropTargetForOffset(details.globalPosition);
    } else {
      editorState.selectionService.removeDropTarget();
    }
  }

  Future<void> _onDragDone(DropDoneDetails details) async {
    editorState.selectionService.removeDropTarget();

    final data = editorState.selectionService
        .getDropTargetRenderData(details.globalPosition);

    if (data != null) {
      final cursorNode = data.cursorNode;
      final dropPath = data.dropPath;

      if (cursorNode != null && dropPath != null) {
        if (_excludeFromDropTarget.contains(cursorNode.type)) {
          return;
        }

        final node = editorState.getNodeAtPath(dropPath);

        if (node == null) {
          return;
        }

        for (final file in details.files) {
          final fileName = file.name.toLowerCase();
          if (file.mimeType?.startsWith('image/') ??
              false || imgExtensionRegex.hasMatch(fileName)) {
            await editorState.dropImages(node, [file], viewId, isLocalMode);
          } else {
            await editorState.dropFiles(node, [file], viewId, isLocalMode);
          }
        }
      }
    }
  }
}
