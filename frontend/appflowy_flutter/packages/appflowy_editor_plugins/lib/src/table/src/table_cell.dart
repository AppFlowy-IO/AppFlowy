import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/models/table_data_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TableCell extends StatefulWidget {
  const TableCell({
    Key? key,
    required this.colIdx,
    required this.rowIdx,
    required this.editorState,
    required this.node,
  }) : super(key: key);

  final int colIdx;
  final int rowIdx;
  final EditorState editorState;
  final Node node;

  @override
  State<TableCell> createState() => _TableCellState();
}

class _TableCellState extends State<TableCell> {
  late TextNode _textNode;

  @override
  void initState() {
    final cellData =
        context.read<TableData>().getCell(widget.colIdx, widget.rowIdx);

    _textNode = Node.fromJson(cellData) as TextNode;
    _textNode.addListener(() => context
        .read<TableData>()
        .setCell(widget.colIdx, widget.rowIdx, _textNode.toJson()));
    // Not using widget.node.insert because it triggers notifyListener and that
    // causes exception of setState() or markNeedsBuild() called during build
    widget.node.children.add(_textNode);
    _textNode.parent = widget.node;

    context.read<TableData>().setNode(widget.colIdx, widget.rowIdx, _textNode);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight:
            context.select((TableData td) => td.getRowHeight(widget.rowIdx)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          widget.editorState.service.renderPluginService.buildPluginWidget(
            NodeWidgetContext<TextNode>(
              context: context,
              node: _textNode,
              editorState: widget.editorState,
            ),
            afterNodeBuildCB,
          )
        ],
      ),
    );

    /*return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (SizeChangedLayoutNotification notification) {
        print('BBBBBBBBBBBBBBB ${context.size}');
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: widget.editorState.service.renderPluginService.buildPluginWidget(
          NodeWidgetContext<TextNode>(
            context: context,
            node: _textNode,
            editorState: widget.editorState,
          ),
        ),
      ),
    );*/
  }

  Future<void> afterNodeBuildCB() async {
    if (!mounted) {
      return;
    }
    context.read<TableData>().notifyNodeUpdate(widget.colIdx, widget.rowIdx);
  }
}
