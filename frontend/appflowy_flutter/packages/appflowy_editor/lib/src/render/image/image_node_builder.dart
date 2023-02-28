import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/infra/clipboard.dart';
import 'package:appflowy_editor/src/render/action_menu/action_menu.dart';
import 'package:appflowy_editor/src/render/action_menu/action_menu_item.dart';
import 'package:appflowy_editor/src/service/render_plugin_service.dart';
import 'package:flutter/material.dart';

import 'image_node_widget.dart';

class ImageNodeBuilder extends NodeWidgetBuilder<Node>
    with ActionProvider<Node> {
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

  @override
  List<ActionMenuItem> actions(NodeWidgetContext<Node> context) {
    return [
      ActionMenuItem.svg(
        name: 'image_toolbar/align_left',
        selected: () {
          final align = context.node.attributes['align'];
          return _textToAlignment(align) == Alignment.centerLeft;
        },
        onPressed: () => _onAlign(context, Alignment.centerLeft),
      ),
      ActionMenuItem.svg(
        name: 'image_toolbar/align_center',
        selected: () {
          final align = context.node.attributes['align'];
          return _textToAlignment(align) == Alignment.center;
        },
        onPressed: () => _onAlign(context, Alignment.center),
      ),
      ActionMenuItem.svg(
        name: 'image_toolbar/align_right',
        selected: () {
          final align = context.node.attributes['align'];
          return _textToAlignment(align) == Alignment.centerRight;
        },
        onPressed: () => _onAlign(context, Alignment.centerRight),
      ),
      ActionMenuItem.separator(),
      ActionMenuItem.svg(
        name: 'image_toolbar/copy',
        onPressed: () {
          final src = context.node.attributes['image_src'];
          AppFlowyClipboard.setData(text: src);
        },
      ),
      ActionMenuItem.svg(
        name: 'image_toolbar/delete',
        onPressed: () {
          final transaction = context.editorState.transaction
            ..deleteNode(context.node);
          context.editorState.apply(transaction);
        },
      ),
    ];
  }

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

  void _onAlign(NodeWidgetContext context, Alignment alignment) {
    final transaction = context.editorState.transaction
      ..updateNode(context.node, {
        'align': _alignmentToText(alignment),
      });
    context.editorState.apply(transaction);
  }
}
