import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/infra/clipboard.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:rich_clipboard/rich_clipboard.dart';
import 'package:appflowy_editor/src/render/image/local_image_node_widget.dart';
import 'package:appflowy_editor/src/render/image/network_image_node_widget.dart';
>>>>>>> c066f53cd (feat: pick local image files)

import 'image_node_widget.dart';

class ImageNodeBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    final src = context.node.attributes['image_src'];
    final type = context.node.attributes['type'];
    final align = context.node.attributes['align'];
    var widget;
    double? width;
    if (context.node.attributes.containsKey('width')) {
      width = context.node.attributes['width'].toDouble();
    }
<<<<<<< HEAD
    return ImageNodeWidget(
      key: context.node.key,
      node: context.node,
      src: src,
      width: width,
      alignment: _textToAlignment(align),
      onCopy: () {
        AppFlowyClipboard.setData(text: src);
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
=======
    if (type == 'network') {
      widget = NetworkImageNode(
        key: context.node.key,
        node: context.node,
        src: src,
        type: type,
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
    } else if (type == 'file') {
      widget = LocalImageNode(
        key: context.node.key,
        node: context.node,
        src: src,
        type: type,
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
    } else {
      print('type cannnot be found?');
    }
    return widget;
>>>>>>> c066f53cd (feat: pick local image files)
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
