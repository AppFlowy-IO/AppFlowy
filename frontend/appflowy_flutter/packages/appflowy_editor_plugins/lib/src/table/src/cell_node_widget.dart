import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CellNodeWidget extends StatefulWidget {
  const CellNodeWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<CellNodeWidget> createState() => _CellNodeWidgetState();
}

class _CellNodeWidgetState extends State<CellNodeWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: context.select((Node n) => n.attributes['height']),
      ),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: widget.editorState.service.renderPluginService
                .buildPluginWidget(
              NodeWidgetContext<TextNode>(
                context: context,
                node: widget.node.children.first as TextNode,
                editorState: widget.editorState,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
