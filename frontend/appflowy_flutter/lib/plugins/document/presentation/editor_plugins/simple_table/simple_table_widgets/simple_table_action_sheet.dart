import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SimpleTableActionSheet extends StatefulWidget {
  const SimpleTableActionSheet({
    super.key,
    required this.index,
    required this.type,
    required this.node,
  });

  final int index;
  final SimpleTableMoreActionType type;
  final Node node;

  @override
  State<SimpleTableActionSheet> createState() => _SimpleTableActionSheetState();
}

class _SimpleTableActionSheetState extends State<SimpleTableActionSheet> {
  final ValueNotifier<bool> isShowingMenu = ValueNotifier(false);

  late final EditorState editorState = context.read<EditorState>();
  late final SimpleTableContext simpleTableContext =
      context.read<SimpleTableContext>();

  @override
  void initState() {
    super.initState();

    simpleTableContext.selectingRow.addListener(_onUpdateShowingMenu);
    simpleTableContext.selectingColumn.addListener(_onUpdateShowingMenu);
  }

  @override
  void dispose() {
    isShowingMenu.dispose();
    simpleTableContext.selectingRow.removeListener(_onUpdateShowingMenu);
    simpleTableContext.selectingColumn.removeListener(_onUpdateShowingMenu);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('tap ${widget.type.name}, ${widget.index}');
        _onSelecting();
      },
      child: Container(
        color: Colors.green.withOpacity(0.5),
        height: widget.type == SimpleTableMoreActionType.column
            ? SimpleTableConstants.columnActionSheetHitTestAreaHeight
            : null,
        width: widget.type == SimpleTableMoreActionType.row
            ? SimpleTableConstants.rowActionSheetHitTestAreaWidth
            : null,
        child: Align(
          child: SimpleTableReorderButton(
            isShowingMenu: isShowingMenu,
            type: widget.type,
          ),
        ),
      ),
    );
  }

  void _onSelecting() {
    // update the selecting row or column
    switch (widget.type) {
      case SimpleTableMoreActionType.column:
        context.read<SimpleTableContext>().selectingColumn.value = widget.index;
        context.read<SimpleTableContext>().selectingRow.value = null;
        break;
      case SimpleTableMoreActionType.row:
        context.read<SimpleTableContext>().selectingRow.value = widget.index;
        context.read<SimpleTableContext>().selectingColumn.value = null;
    }

    Future.delayed(Durations.short3, () {
      if (!editorState.isDisposed) {
        editorState.selection = null;
      }
    });
  }

  void _onUpdateShowingMenu() {
    // highlight the reorder button when the row or column is selected
    final selectingRow = simpleTableContext.selectingRow.value;
    final selectingColumn = simpleTableContext.selectingColumn.value;

    if (selectingRow == widget.index &&
        widget.type == SimpleTableMoreActionType.row) {
      isShowingMenu.value = true;
    } else if (selectingColumn == widget.index &&
        widget.type == SimpleTableMoreActionType.column) {
      isShowingMenu.value = true;
    } else {
      isShowingMenu.value = false;
    }
  }
}
