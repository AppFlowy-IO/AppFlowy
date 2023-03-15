import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_editor_plugins/src/table/src/models/table_data_model.dart';
import 'package:provider/provider.dart';

class CellNodeWidget extends StatefulWidget {
  const CellNodeWidget({
    Key? key,
    required this.node,
    required this.textNode,
    required this.editorState,
    required this.colIdx,
    required this.rowIdx,
  }) : super(key: key);

  final Node node;
  final TextNode textNode;
  final EditorState editorState;
  final int colIdx;
  final int rowIdx;

  @override
  State<CellNodeWidget> createState() => _CellNodeWidgetState();
}

class _CellNodeWidgetState extends State<CellNodeWidget> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        cursor: SystemMouseCursors.text,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: widget.editorState.service.renderPluginService
                  .buildPluginWidget(
                NodeWidgetContext<TextNode>(
                  context: context,
                  node: widget.textNode,
                  editorState: widget.editorState,
                ),
                afterNodeBuildCB,
              ),
            ),
          ],
        ));
  }

  Future<void> afterNodeBuildCB() async {
    if (!mounted) {
      return;
    }
    context.read<TableData>().notifyNodeUpdate(widget.colIdx, widget.rowIdx);
  }
}
