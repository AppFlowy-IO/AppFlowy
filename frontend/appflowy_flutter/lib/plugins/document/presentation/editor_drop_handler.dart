import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/document/presentation/editor_drop_manager.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_file.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/paste_from_image.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/file/file_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy/shared/patterns/file_type_patterns.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:provider/provider.dart';

const _excludeFromDropTarget = [
  ImageBlockKeys.type,
  CustomImageBlockKeys.type,
  MultiImageBlockKeys.type,
  FileBlockKeys.type,
];

class EditorDropHandler extends StatefulWidget {
  const EditorDropHandler({
    super.key,
    required this.viewId,
    required this.editorState,
    required this.child,
  });

  final String viewId;
  final EditorState editorState;
  final Widget child;

  @override
  State<EditorDropHandler> createState() => _EditorDropHandlerState();
}

class _EditorDropHandlerState extends State<EditorDropHandler> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Due to how DropTarget works, there is no way to differentiate if an overlay is
      // blocking the target visibly, so when we have an overlay with a drop target,
      // we should disable the drop target for the Editor, until it is closed.
      //
      // See FileBlockComponent for sample use.
      //
      // Relates to:
      // - https://github.com/MixinNetwork/flutter-plugins/issues/2
      // - https://github.com/MixinNetwork/flutter-plugins/issues/331
      //
      create: (_) => EditorDropManagerState(),
      child: Builder(
        builder: (context) {
          return Consumer<EditorDropManagerState>(
            builder: (context, dropState, _) {
              return Builder(
                builder: (context) {
                  return DropTarget(
                    enable: dropState.isDropEnabled,
                    onDragExited: (_) =>
                        widget.editorState.selectionService.removeDropTarget(),
                    onDragUpdated: (details) {
                      final data = widget.editorState.selectionService
                          .getDropTargetRenderData(details.globalPosition);

                      if (data != null &&
                          data.dropPath != null &&

                          // We implement custom Drop logic for image blocks, this is
                          // how we can exclude them from the Drop Target
                          !_excludeFromDropTarget
                              .contains(data.cursorNode?.type)) {
                        // Render the drop target
                        widget.editorState.selectionService
                            .renderDropTargetForOffset(details.globalPosition);
                      } else {
                        widget.editorState.selectionService.removeDropTarget();
                      }
                    },
                    onDragDone: (details) async {
                      final editorState = widget.editorState;
                      editorState.selectionService.removeDropTarget();

                      final data = editorState.selectionService
                          .getDropTargetRenderData(details.globalPosition);

                      if (data != null) {
                        final cursorNode = data.cursorNode;
                        final dropPath = data.dropPath;

                        if (cursorNode != null && dropPath != null) {
                          if (_excludeFromDropTarget
                              .contains(cursorNode.type)) {
                            return;
                          }

                          final node = editorState.getNodeAtPath(dropPath);

                          if (node == null) {
                            return;
                          }

                          final isLocalMode =
                              context.read<DocumentBloc>().isLocalMode;
                          final List<XFile> imageFiles = [];
                          final List<XFile> otherFiles = [];

                          for (final file in details.files) {
                            final fileName = file.name.toLowerCase();
                            if (file.mimeType?.startsWith('image/') ??
                                false || imgExtensionRegex.hasMatch(fileName)) {
                              imageFiles.add(file);
                            } else {
                              otherFiles.add(file);
                            }
                          }

                          await editorState.dropImages(
                            node,
                            imageFiles,
                            widget.viewId,
                            isLocalMode,
                          );

                          await editorState.dropFiles(
                            node,
                            otherFiles,
                            widget.viewId,
                            isLocalMode,
                          );
                        }
                      }
                    },
                    child: widget.child,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
