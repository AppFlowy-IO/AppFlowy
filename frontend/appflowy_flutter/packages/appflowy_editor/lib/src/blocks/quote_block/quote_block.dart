import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/blocks/base_component/widget/nested_list.dart';
import 'package:appflowy_editor/src/infra/flowy_svg.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    final editorState = Provider.of<EditorState>(context);
    final nodes = widget.node.children.toList(growable: false);
    return NestedList(
      nestedChildren:
          editorState.service.renderPluginService.buildPluginWidgets(
        context,
        nodes,
        editorState,
      ),
      child: const FlowySvg(
        width: 10,
        name: 'quote',
      ),
    );
  }
}
