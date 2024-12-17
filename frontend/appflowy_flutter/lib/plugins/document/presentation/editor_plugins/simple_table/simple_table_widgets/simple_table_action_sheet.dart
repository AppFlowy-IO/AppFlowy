import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

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

  @override
  void dispose() {
    isShowingMenu.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('tap ${widget.type.name}, ${widget.index}');
      },
      child: Container(
        color: Colors.red,
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
}
