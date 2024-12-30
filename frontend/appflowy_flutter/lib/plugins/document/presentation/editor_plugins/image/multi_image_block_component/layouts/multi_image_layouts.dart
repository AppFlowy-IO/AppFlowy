import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/layouts/image_browser_layout.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/layouts/image_grid_layout.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/image/multi_image_block_component/multi_image_block_component.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide ResizableImage;

abstract class ImageBlockMultiLayout extends StatefulWidget {
  const ImageBlockMultiLayout({
    super.key,
    required this.node,
    required this.editorState,
    required this.images,
    required this.indexNotifier,
    required this.isLocalMode,
  });

  final Node node;
  final EditorState editorState;
  final List<ImageBlockData> images;
  final ValueNotifier<int> indexNotifier;
  final bool isLocalMode;
}

class ImageLayoutRender extends StatelessWidget {
  const ImageLayoutRender({
    super.key,
    required this.node,
    required this.editorState,
    required this.images,
    required this.indexNotifier,
    required this.isLocalMode,
    required this.onIndexChanged,
  });

  final Node node;
  final EditorState editorState;
  final List<ImageBlockData> images;
  final ValueNotifier<int> indexNotifier;
  final bool isLocalMode;
  final void Function(int) onIndexChanged;

  @override
  Widget build(BuildContext context) {
    final layout = _getLayout();

    return _buildLayout(layout);
  }

  MultiImageLayout _getLayout() {
    return MultiImageLayout.fromIntValue(
      node.attributes[MultiImageBlockKeys.layout] ?? 0,
    );
  }

  Widget _buildLayout(MultiImageLayout layout) {
    switch (layout) {
      case MultiImageLayout.grid:
        return ImageGridLayout(
          node: node,
          editorState: editorState,
          images: images,
          indexNotifier: indexNotifier,
          isLocalMode: isLocalMode,
        );
      case MultiImageLayout.browser:
      default:
        return ImageBrowserLayout(
          node: node,
          editorState: editorState,
          images: images,
          indexNotifier: indexNotifier,
          isLocalMode: isLocalMode,
          onIndexChanged: onIndexChanged,
        );
    }
  }
}
