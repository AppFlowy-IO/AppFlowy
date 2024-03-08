import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/image_placeholder.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:flutter/material.dart';

final customImageMenuItem = SelectionMenuItem(
  getName: () => AppFlowyEditorL10n.current.image,
  icon: (editorState, isSelected, style) => SelectionMenuIconWidget(
    name: 'image',
    isSelected: isSelected,
    style: style,
  ),
  keywords: ['image', 'picture', 'img', 'photo'],
  handler: (editorState, menuService, context) async {
    // use the key to retrieve the state of the image block to show the popover automatically
    final imagePlaceholderKey = GlobalKey<ImagePlaceholderState>();
    await editorState.insertEmptyImageBlock(imagePlaceholderKey);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      imagePlaceholderKey.currentState?.controller.show();
    });
  },
);

extension InsertImage on EditorState {
  Future<void> insertEmptyImageBlock(GlobalKey key) async {
    final selection = this.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }
    final node = getNodeAtPath(selection.end.path);
    if (node == null) {
      return;
    }
    final emptyImage = imageNode(url: '')
      ..extraInfos = {
        kImagePlaceholderKey: key,
      };
    final transaction = this.transaction;
    // if the current node is empty paragraph, replace it with image node
    if (node.type == ParagraphBlockKeys.type &&
        (node.delta?.isEmpty ?? false)) {
      transaction
        ..insertNode(
          node.path,
          emptyImage,
        )
        ..deleteNode(node);
    } else {
      transaction.insertNode(
        node.path.next,
        emptyImage,
      );
    }

    transaction.afterSelection = Selection.collapsed(
      Position(
        path: node.path.next,
      ),
    );
    transaction.selectionExtraInfo = {};

    return apply(transaction);
  }
}
