import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/base_component/selectable/text_selectable_state_mixin.dart';
import 'package:appflowy_editor/src/block/base_component/widget/nested_list.dart';
import 'package:appflowy_editor/src/block/text_block/text_block_with_icon.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BulletedListBlock extends StatefulWidget {
  const BulletedListBlock({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  State<BulletedListBlock> createState() => _BulletedListBlockState();
}

class _BulletedListBlockState extends State<BulletedListBlock>
    with TextBlockSelectableStateMixin<BulletedListBlock> {
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
    final node = widget.node;
    final delta = Delta.fromJson(List.from(node.attributes['texts']));
    final nodes = widget.node.children.toList(growable: false);

    return PaddingNestedList(
      nestedChildren:
          editorState.service.renderPluginService.buildPluginWidgets(
        context,
        nodes,
        editorState,
      ),
      child: TextBlockWithIcon(
        icon: Text('$_prefix  '),
        textBlockKey: textBlockKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        path: node.path,
        delta: delta,
      ),
    );
  }
}
