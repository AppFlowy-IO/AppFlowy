import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BulletedListBlockBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return BulletedListBlock(
      key: context.node.key,
      node: context.node,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}

class BulletedListBlock extends StatefulWidget {
  const BulletedListBlock({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  State<BulletedListBlock> createState() => _BulletedListBlockState();
}

class _BulletedListBlockState extends State<BulletedListBlock> {
  int get level {
    var level = 1;
    var parent = widget.node.parent;
    while (parent != null) {
      if (parent.type == 'bulleted_list') {
        level += 1;
      }
      parent = parent.parent;
    }
    return level;
  }

  @override
  Widget build(BuildContext context) {
    final editorState = Provider.of<EditorState>(context);
    final children = widget.node.children.toList(growable: false);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('⭐️' * level),
        Flexible(
            child: Column(
          children: children
              .map(
                (child) =>
                    editorState.service.renderPluginService.buildPluginWidget(
                  child is TextNode
                      ? NodeWidgetContext<TextNode>(
                          context: context,
                          node: child,
                          editorState: editorState,
                        )
                      : NodeWidgetContext<Node>(
                          context: context,
                          node: child,
                          editorState: editorState,
                        ),
                ),
              )
              .toList(growable: false),
        ))
      ],
    );
  }
}
