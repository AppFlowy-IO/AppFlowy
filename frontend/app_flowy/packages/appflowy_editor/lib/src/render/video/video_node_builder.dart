import 'package:appflowy_editor/src/document/node.dart';
import 'package:appflowy_editor/src/operation/transaction_builder.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';
import 'package:rich_clipboard/rich_clipboard.dart';

import 'video_node_widget.dart';

class VideoNodeBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    final src = context.node.attributes['video_src'];
    final align = context.node.attributes['align'];
    double? width;
    if (context.node.attributes.containsKey('width')) {
      width = context.node.attributes['width'].toDouble();
    }
    return VideoNodeWidget(
      key: context.node.key,
      node: context.node,
      src: src,
      width: width,
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
      onResize: (width) {
        TransactionBuilder(context.editorState)
          ..updateNode(context.node, {
            'width': width,
          })
          ..commit();
      },
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => ((node) {
        return node.type == 'video' &&
            node.attributes.containsKey('video_src') &&
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
