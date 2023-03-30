import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/base_component/nested_list.dart';
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
  static final _bulletListPrefixes = [
    '♠',
    '♥',
    '♣',
    '♦',
  ];

  int get _level {
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

  String get _prefix =>
      _bulletListPrefixes[_level % _bulletListPrefixes.length];

  @override
  Widget build(BuildContext context) {
    final editorState = Provider.of<EditorState>(context);
    final nodes = widget.node.children.toList(growable: false);
    return NestedList(
      nestedChildren:
          editorState.service.renderPluginService.buildPluginWidgets(
        context,
        nodes,
        editorState,
      ),
      child: Text('$_prefix  '),
    );
  }
}
