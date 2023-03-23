import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/table_node.dart';
import 'package:flutter/material.dart';
import 'src/table_view.dart';

class TableNodeWidgetBuilder extends NodeWidgetBuilder<Node>
    with ActionProvider<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return TableNodeWidget(
      key: context.node.key,
      tableNode: TableNode(node: context.node),
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) =>
      node.attributes.isNotEmpty &&
      node.attributes.containsKey('colsLen') &&
      node.attributes.containsKey('rowsLen');

  @override
  List<ActionMenuItem> actions(NodeWidgetContext<Node> context) {
    return [
      ActionMenuItem.icon(
        iconData: Icons.content_copy,
        onPressed: () {
          final selection = context
              .editorState.service.selectionService.currentSelection.value;
          final transaction = context.editorState.transaction
            ..insertNode(context.node.path.next, context.node.copyWith())
            ..afterSelection = selection;
          context.editorState.apply(transaction);
        },
      ),
      ActionMenuItem.svg(
        name: 'delete',
        onPressed: () {
          final transaction = context.editorState.transaction
            ..deleteNode(context.node);
          context.editorState.apply(transaction);
        },
      ),
    ];
  }
}

class TableNodeWidget extends StatefulWidget {
  const TableNodeWidget({
    Key? key,
    required this.tableNode,
    required this.editorState,
  }) : super(key: key);

  final TableNode tableNode;
  final EditorState editorState;

  @override
  State<TableNodeWidget> createState() => _TableNodeWidgetState();
}

class _TableNodeWidgetState extends State<TableNodeWidget>
    with SelectableMixin {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.only(right: 30, top: 8),
          child: TableView(
            tableNode: widget.tableNode,
            editorState: widget.editorState,
          ),
        ),
      ),
    );
  }

  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  @override
  Position start() => Position(path: widget.tableNode.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.tableNode.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  List<Rect> getRectsInSelection(Selection selection) => [
        Offset.zero &
            Size(widget.tableNode.tableWidth + 10,
                widget.tableNode.colsHeight + 10)
      ];

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.tableNode.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  bool get shouldCursorBlink => false;

  @override
  Offset localToGlobal(Offset offset) => _renderBox.localToGlobal(offset);
}

SelectionMenuItem tableMenuItem = SelectionMenuItem(
  name: 'Table',
  icon: (editorState, onSelected) => Icon(
    Icons.table_view,
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
    size: 18.0,
  ),
  keywords: ['table'],
  handler: (editorState, _, __) {
    final selection =
        editorState.service.selectionService.currentSelection.value;
    final textNodes = editorState.service.selectionService.currentSelectedNodes
        .whereType<TextNode>();
    if (textNodes.length != 1 || selection == null) {
      return;
    }
    final textNode = textNodes.first;

    final Path path;
    final Selection afterSelection;
    if (textNode.toPlainText().isEmpty) {
      path = textNode.path;
      afterSelection = Selection.single(
        path: path.next,
        startOffset: 0,
      );
    } else {
      path = selection.end.path.next;
      afterSelection = selection;
    }

    final tableNode = TableNode.fromList([
      ['', ''],
      ['', '']
    ]);

    final transaction = editorState.transaction
      ..insertNode(path, tableNode.node)
      ..afterSelection = afterSelection;
    editorState.apply(transaction);
  },
);
