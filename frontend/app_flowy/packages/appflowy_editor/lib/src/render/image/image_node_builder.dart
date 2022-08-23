import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

import 'image_node_widget.dart';

class ImageNodeBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    final src = context.node.attributes['image_src'];
    final align = context.node.attributes['align'];
    return ImageNodeWidget(
      key: context.node.key,
      src: src,
      alignment: _textToAlignment(align),
      onCopy: () {
        RichClipboard.setData(RichClipboardData(text: src));
      },
      onDelete: () {
        TransactionBuilder(context.editorState)
          ..deleteNode(context.node)
          ..commit();
      },
      onAlign: (alignment) {
        TransactionBuilder(context.editorState)
          ..updateNode(context.node, {
            'align': _alignmentToText(alignment),
          })
          ..commit();
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
    if (text == 'center') {
      return Alignment.center;
    } else if (text == 'left') {
      return Alignment.centerLeft;
    } else if (text == 'right') {
      return Alignment.centerRight;
    }
    throw UnimplementedError();
  }

  String _alignmentToText(Alignment alignment) {
    if (alignment == Alignment.center) {
      return 'center';
    } else if (alignment == Alignment.centerLeft) {
      return 'left';
    } else if (alignment == Alignment.centerRight) {
      return 'right';
    }
    throw UnimplementedError();
  }
}
