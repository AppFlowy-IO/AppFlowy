import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/models/table_data_model.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_col.dart';

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
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.only(right: 30, top: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  children: [
                    Row(
                      children: [
                        ..._buildColumns(context),
                        Padding(
                          padding: const EdgeInsets.only(left: 1),
                          child: ActionMenuWidget(items: [
                            ActionMenuItem.icon(
                                iconData: Icons.add,
                                onPressed: () {
                                  context.read<TableData>().addCol();
                                }),
                          ]),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 1, right: 32),
                      child: ActionMenuWidget(items: [
                        ActionMenuItem.icon(
                            iconData: Icons.add,
                            onPressed: () {
                              context.read<TableData>().addRow();
                            }),
                      ]),
                    )
                  ],
                ),
              ],
            ),
          );
        });
  }

  List<Widget> _buildColumns(BuildContext context) {
    var colsLen = context.select((TableData td) => td.colsLen);
    var cols = [];

    for (var i = 0; i < colsLen; i++) {
      cols.add(TableCol(
          colIdx: i, editorState: widget.editorState, node: widget.node));
    }

    return [
      Container(
        width: 2,
        height: context.select((TableData td) => td.colsHeight),
        color: Colors.grey,
      ),
      ...cols,
    ];
  }
}
