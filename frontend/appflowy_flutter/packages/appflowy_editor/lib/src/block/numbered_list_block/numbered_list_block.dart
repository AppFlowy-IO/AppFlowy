import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/block/base_component/selectable/text_selectable_state_mixin.dart';
import 'package:appflowy_editor/src/block/base_component/widget/nested_list.dart';
import 'package:appflowy_editor/src/block/text_block/text_block_with_icon.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NumberedListBlock extends StatefulWidget {
  const NumberedListBlock({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  State<NumberedListBlock> createState() => _NumberedListBlockState();
}

class _NumberedListBlockState extends State<NumberedListBlock>
    with TextBlockSelectableStateMixin<NumberedListBlock> {
  int get _level {
    var level = 1;
    var previousSibling = widget.node.previous;
    if (previousSibling != null && previousSibling.type == 'numbered_list') {
      level += 1;
    }
    return level;
  }

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
        icon: FlowySvg(
          number: _level,
        ),
        textBlockKey: textBlockKey,
        crossAxisAlignment: CrossAxisAlignment.start,
        path: node.path,
        delta: delta,
      ),
    );
  }
}
