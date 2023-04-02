import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/text_block/text_block_with_icon.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:appflowy_editor/src/render/selection/v2/selectable_v2.dart';
import 'package:flutter/material.dart';

class QuoteBlock extends StatefulWidget {
  const QuoteBlock({
    super.key,
    required this.node,
  });

  final Node node;

  @override
  State<QuoteBlock> createState() => _QuoteBlockState();
}

class _QuoteBlockState extends State<QuoteBlock>
    implements SelectableState<QuoteBlock> {
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

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final delta = Delta.fromJson(List.from(node.attributes['texts']));
    return IntrinsicHeight(
      child: TextBlockWithIcon(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        icon: const FlowySvg(
          width: 20,
          name: 'quote',
        ),
        textBlockKey: textBlockKey,
        path: node.path,
        delta: delta,
      ),
    );
  }
}
