import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/text_block/shortcuts/text_block_shortcuts.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/selection/v2/selectable_v2.dart';
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
    implements SelectableState<NumberedListBlock> {
  final GlobalKey textBlockKey = GlobalKey();

  @override
  Position getPositionInOffset(Offset offset) {
    return (textBlockKey.currentState as TextBlockState)
        .getPositionInOffset(offset);
  }

  @override
  Future<void> setSelectionV2(Selection? selection) {
    return (textBlockKey.currentState as TextBlockState)
        .setSelectionV2(selection);
  }

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FlowySvg(
              number: _level,
            ),
            TextBlock(
              key: textBlockKey,
              path: node.path,
              delta: delta,
              shortcuts: textBlockShortcuts,
            ),
            // children
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                editorState.service.renderPluginService.buildPluginWidgets(
              context,
              nodes,
              editorState,
            ),
          ),
        ),
      ],
    );
  }
}
