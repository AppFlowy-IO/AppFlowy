import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
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
    required this.isShowingMenu,
  });

  final int index;
  final SimpleTableMoreActionType type;
  final Node node;
  final ValueNotifier<bool> isShowingMenu;

  @override
  State<SimpleTableActionSheet> createState() => _SimpleTableActionSheetState();
}

class _SimpleTableActionSheetState extends State<SimpleTableActionSheet> {
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
    simpleTableContext.selectingRow.removeListener(_onUpdateShowingMenu);
    simpleTableContext.selectingColumn.removeListener(_onUpdateShowingMenu);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async => _onSelecting(),
      child: SizedBox(
        height: widget.type == SimpleTableMoreActionType.column
            ? SimpleTableConstants.columnActionSheetHitTestAreaHeight
            : null,
        width: widget.type == SimpleTableMoreActionType.row
            ? SimpleTableConstants.rowActionSheetHitTestAreaWidth
            : null,
        child: Align(
          child: SimpleTableReorderButton(
            isShowingMenu: widget.isShowingMenu,
            type: widget.type,
          ),
        ),
      ),
    );
  }

  Future<void> _onSelecting() async {
    widget.isShowingMenu.value = true;

    // update the selecting row or column
    switch (widget.type) {
      case SimpleTableMoreActionType.column:
        simpleTableContext.selectingColumn.value = widget.index;
        simpleTableContext.selectingRow.value = null;
        break;
      case SimpleTableMoreActionType.row:
        simpleTableContext.selectingRow.value = widget.index;
        simpleTableContext.selectingColumn.value = null;
    }

    Future.delayed(Durations.short3, () {
      if (!editorState.isDisposed) {
        editorState.selection = null;
      }
    });

    // show the bottom sheet
    await showMobileBottomSheet(
      context,
      showHeader: true,
      title: widget.type.name,
      showCloseButton: true,
      showDragHandle: true,
      showDivider: false,
      builder: (context) => SimpleTableBottomSheet(
        type: widget.type,
        node: widget.node,
        editorState: editorState,
      ),
    );

    // reset the selecting row or column
    simpleTableContext.selectingRow.value = null;
    simpleTableContext.selectingColumn.value = null;

    widget.isShowingMenu.value = false;
  }

  void _onUpdateShowingMenu() {
    // highlight the reorder button when the row or column is selected
    final selectingRow = simpleTableContext.selectingRow.value;
    final selectingColumn = simpleTableContext.selectingColumn.value;

    if (selectingRow == widget.index &&
        widget.type == SimpleTableMoreActionType.row) {
      widget.isShowingMenu.value = true;
    } else if (selectingColumn == widget.index &&
        widget.type == SimpleTableMoreActionType.column) {
      widget.isShowingMenu.value = true;
    } else {
      widget.isShowingMenu.value = false;
    }
  }
}
