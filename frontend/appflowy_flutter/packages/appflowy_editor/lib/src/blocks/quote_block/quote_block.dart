import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:flutter/material.dart';

class QuoteBlock extends StatefulWidget {
  const QuoteBlock({
    super.key,
    required this.node,
    required this.textKey,
  });

  final Node node;
  final GlobalKey textKey;

  @override
  State<QuoteBlock> createState() => _QuoteBlockState();
}

class _QuoteBlockState extends State<QuoteBlock> {
  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final delta = Delta.fromJson(List.from(node.attributes['texts']));
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FlowySvg(
            width: 20,
            name: 'quote',
          ),
          TextBlock(
            key: widget.textKey,
            path: node.path,
            delta: delta,
          )
        ],
      ),
    );
  }
}
