import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy/util/throttle.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

final Throttler throttler =
    Throttler(duration: const Duration(milliseconds: 100));

class SimpleTableDraggableReorderButton extends StatelessWidget {
  const SimpleTableDraggableReorderButton({
    super.key,
    required this.node,
    required this.index,
    required this.isShowingMenu,
    required this.type,
    required this.editorState,
    required this.simpleTableContext,
  });

  final Node node;
  final int index;
  final ValueNotifier<bool> isShowingMenu;
  final SimpleTableMoreActionType type;
  final EditorState editorState;
  final SimpleTableContext simpleTableContext;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) => _startDragging(),
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: (_) => _stopDragging(),
      onHorizontalDragStart: (_) => _startDragging(),
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: (_) => _stopDragging(),
      onTap: () {},
      child: SimpleTableReorderButton(
        isShowingMenu: isShowingMenu,
        type: type,
      ),
    );
  }

  void _startDragging() {
    debugPrint('[x] startDragging');
    switch (type) {
      case SimpleTableMoreActionType.column:
        simpleTableContext.isReorderingColumn.value = (true, index);
      case SimpleTableMoreActionType.row:
        simpleTableContext.isReorderingRow.value = (true, index);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    // debugPrint('[x] onDragUpdate: $details');
    simpleTableContext.reorderingOffset.value = details.globalPosition;
  }

  void _stopDragging() {
    switch (type) {
      case SimpleTableMoreActionType.column:
        simpleTableContext.isReorderingColumn.value = (false, -1);
      case SimpleTableMoreActionType.row:
        simpleTableContext.isReorderingRow.value = (false, -1);
    }
  }
}

class SimpleTableReorderButton extends StatelessWidget {
  const SimpleTableReorderButton({
    super.key,
    required this.isShowingMenu,
    required this.type,
  });

  final ValueNotifier<bool> isShowingMenu;
  final SimpleTableMoreActionType type;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: isShowingMenu,
      builder: (context, isShowingMenu, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            decoration: BoxDecoration(
              color: isShowingMenu
                  ? context.simpleTableMoreActionHoverColor
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: context.simpleTableMoreActionBorderColor,
              ),
            ),
            height: 16.0,
            width: 16.0,
            child: FlowySvg(
              type.reorderIconSvg,
              color: isShowingMenu ? Colors.white : null,
              size: const Size.square(16.0),
            ),
          ),
        );
      },
    );
  }
}

class SimpleTableFeedback extends StatefulWidget {
  const SimpleTableFeedback({
    super.key,
    required this.editorState,
    required this.node,
    required this.type,
    required this.index,
  });

  /// The node of the table.
  /// Its type must be [SimpleTableBlockKeys.type].
  final Node node;

  /// The type of the more action.
  ///
  /// If the type is [SimpleTableMoreActionType.column], the feedback will use index as column index.
  /// If the type is [SimpleTableMoreActionType.row], the feedback will use index as row index.
  final SimpleTableMoreActionType type;

  /// The index of the column or row.
  final int index;

  final EditorState editorState;

  @override
  State<SimpleTableFeedback> createState() => _SimpleTableFeedbackState();
}

class _SimpleTableFeedbackState extends State<SimpleTableFeedback> {
  final simpleTableContext = SimpleTableContext();
  late final Node dummyNode;

  @override
  void initState() {
    super.initState();

    dummyNode = _buildDummyNode();
    debugPrint('dummyNode: ${dummyNode.toJson()}');
  }

  @override
  void dispose() {
    simpleTableContext.dispose();
    dummyNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.withOpacity(0.2),
      width: 200,
      height: 100,
      alignment: Alignment.center,
      child: FlowyText(
        '${widget.type.toString()} - ${widget.index}',
        fontSize: 18.0,
      ),
      // Provider.value(
      //   value: widget.editorState,
      //   child: SimpleTableWidget(
      //     node: dummyNode,
      //     simpleTableContext: simpleTableContext,
      //     enableAddColumnButton: false,
      //     enableAddRowButton: false,
      //     enableAddColumnAndRowButton: false,
      //     enableHoverEffect: false,
      //     isFeedback: true,
      //   ),
      // ),
    );
  }

  /// Build the dummy node for the feedback.
  ///
  /// For example,
  ///
  /// If the type is [SimpleTableMoreActionType.row], we should build the dummy table node using the data from the first row of the table node.
  /// If the type is [SimpleTableMoreActionType.column], we should build the dummy table node using the data from the first column of the table node.
  Node _buildDummyNode() {
    // deep copy the table node to avoid mutating the original node
    final tableNode = widget.node.copyWith();

    switch (widget.type) {
      case SimpleTableMoreActionType.row:
        if (widget.index >= tableNode.rowLength || widget.index < 0) {
          return simpleTableBlockNode(children: []);
        }

        final row = tableNode.children[widget.index];
        return simpleTableBlockNode(children: [row]);

      case SimpleTableMoreActionType.column:
        if (widget.index >= tableNode.columnLength || widget.index < 0) {
          return simpleTableBlockNode(children: []);
        }

        final rows = tableNode.children.map((row) {
          final cell = row.children[widget.index];
          return simpleTableRowBlockNode(children: [cell]);
        }).toList();
        return simpleTableBlockNode(children: rows);
    }
  }
}
