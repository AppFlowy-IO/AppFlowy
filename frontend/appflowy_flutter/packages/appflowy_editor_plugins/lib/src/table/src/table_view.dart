import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_col.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/models/table_model.dart';

class TableView extends StatefulWidget {
  const TableView({
    Key? key,
    required this.data,
    required this.editorState,
    required this.node,
  }) : super(key: key);

  final TableData data;
  final EditorState editorState;
  final Node node;

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
        value: widget.data,
        child: Container(
          padding: const EdgeInsets.all(8.0),
          width: 225,
          child: Row(
            children: [
              Container(
                height: 100,
                width: 1,
                color: Colors.grey,
              ),
              TableCol(
                colIdx: 0,
                editorState: widget.editorState,
                node: widget.node,
              ),
              Container(
                height: 100,
                width: 1,
                color: Colors.grey,
              ),
              TableCol(
                colIdx: 1,
                editorState: widget.editorState,
                node: widget.node,
              ),
              Container(
                height: 100,
                width: 1,
                color: Colors.grey,
              ),
            ],
          ),
        ));
  }
}
