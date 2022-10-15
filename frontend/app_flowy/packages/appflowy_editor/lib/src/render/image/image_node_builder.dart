import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

import 'image_node_widget.dart';

class ImageNodeBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    final src = context.node.attributes['image_src'];
    final align = context.node.attributes['align'];
    double? width;
    if (context.node.attributes.containsKey('width')) {
      width = context.node.attributes['width'].toDouble();
    }
    return ImageNodeWidget(
      key: context.node.key,
      node: context.node,
      src: src,
      width: width,
      alignment: _textToAlignment(align),
      onCopy: () {
        RichClipboard.setData(RichClipboardData(text: src));
      },
      onDelete: () {
        final transaction = context.editorState.transaction
          ..deleteNode(context.node);
        context.editorState.apply(transaction);
      },
      onAlign: (alignment) {
        final transaction = context.editorState.transaction
          ..updateNode(context.node, {
            'align': _alignmentToText(alignment),
          });
        context.editorState.apply(transaction);
      },
      onResize: (width) {
        final transaction = context.editorState.transaction
          ..updateNode(context.node, {
            'width': width,
          });
        context.editorState.apply(transaction);
      },
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return node.type == 'image' &&
            node.attributes.containsKey('image_src') &&
            node.attributes.containsKey('align');
      });

  Alignment _textToAlignment(String text) {
    if (text == 'left') {
      return Alignment.centerLeft;
    } else if (text == 'right') {
      return Alignment.centerRight;
    }
    return Alignment.center;
  }

  String _alignmentToText(Alignment alignment) {
    if (alignment == Alignment.centerLeft) {
      return 'left';
    } else if (alignment == Alignment.centerRight) {
      return 'right';
    }
    return 'center';
  }
}
