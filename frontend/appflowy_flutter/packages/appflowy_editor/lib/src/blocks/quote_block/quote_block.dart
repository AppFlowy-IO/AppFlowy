import 'package:appflowy_editor/appflowy_editor.dart';
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

class _QuoteBlockState extends State<QuoteBlock> {
  @override
  Widget build(BuildContext context) {
    final nodes = widget.node.children.toList(growable: false);
    assert(nodes.every((element) => element is TextNode));
    return TextBlockWithIcon(
      icon: const FlowySvg(
        width: 20,
        name: 'quote',
      ),
      textNode: widget.node as TextNode,
    );
  }
}
