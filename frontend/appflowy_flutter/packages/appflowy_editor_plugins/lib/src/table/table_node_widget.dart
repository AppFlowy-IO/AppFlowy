import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/models/table_data_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'table_view.dart';

const String kTableType = 'table';
const String kTableDataAttr = 'table_data';

class TableWidgetBuilder extends NodeWidgetBuilder<Node>
    with ActionProvider<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _TableWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) => true;

  @override
  List<ActionMenuItem> actions(NodeWidgetContext<Node> context) {
    return [
      ActionMenuItem.icon(
        iconData: Icons.content_copy,
        onPressed: () {
          final state = context.node.key.currentState as _TableWidgetState?;
          Map<String, dynamic> attributes = {};
          if (state != null) {
            attributes = state.data.toJson();
          }

          final selection = context
              .editorState.service.selectionService.currentSelection.value;
          final transaction = context.editorState.transaction
            ..insertNode(
                context.node.path.next,
                Node(
                  type: kTableType,
                  attributes: attributes,
                ))
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

class _TableWidget extends StatefulWidget {
  const _TableWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<_TableWidget> createState() => _TableWidgetState();
}

class _TableWidgetState extends State<_TableWidget> with SelectableMixin {
  final _scrollController = ScrollController();

  late TableData data;

  @override
  void initState() {
    final dataAttr = widget.node.attributes;
    if (dataAttr['focus'] ?? false) {
      widget.node.addListener(focusFirstCell);
    }
    dataAttr.remove('focus');

    data = dataAttr.isNotEmpty
        ? TableData.fromJson(dataAttr)
        : TableData([
            ['1', '2'],
            ['3', '4']
          ]);

    super.initState();
  }

  @override
  void dispose() {
    widget.node.updateAttributes(data.toJson());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: data,
      builder: (context, _) {
        return Scrollbar(
          controller: _scrollController,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.only(right: 30, top: 8),
              child: TableView(
                node: widget.node,
                editorState: widget.editorState,
              ),
            ),
          ),
        );
      },
    );
  }

  focusFirstCell() {
    if (data.getCellNode(0, 0).parent == null) {
      return;
    }

    final transaction = widget.editorState.transaction
      ..afterSelection = Selection.single(
        path: data.getCellNode(0, 0).path,
        startOffset: 0,
      );
    widget.editorState.apply(transaction);

    widget.node.removeListener(focusFirstCell);
  }

  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  List<Rect> getRectsInSelection(Selection selection) =>
      [Offset.zero & Size(data.colsWidth + 10, data.colsHeight + 10)];

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.node.path,
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

    final transaction = editorState.transaction
      ..insertNode(path, Node(type: kTableType, attributes: {'focus': true}))
      ..afterSelection = afterSelection;
    editorState.apply(transaction);
  },
);
