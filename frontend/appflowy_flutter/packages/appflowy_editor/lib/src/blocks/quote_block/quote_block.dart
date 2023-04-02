import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/base_component/selectable/text_selectable_state_mixin.dart';
import 'package:appflowy_editor/src/blocks/text_block/text_block_with_icon.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
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
    with TextBlockSelectableStateMixin {
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
