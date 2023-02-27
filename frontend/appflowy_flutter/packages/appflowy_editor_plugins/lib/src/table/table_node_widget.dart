import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/src/table/src/models/table_data_model.dart';
import 'package:flutter/material.dart';

import 'table_view.dart';

const String kTableType = 'table';
const String kTableDataAttr = 'table_data';

SelectionMenuItem tableMenuItem = SelectionMenuItem(
  name: () => 'Table',
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
      ..insertNode(path, Node(type: kTableType, attributes: {}))
      ..afterSelection = afterSelection;
    editorState.apply(transaction);
  },
);

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

          final transaction = context.editorState.transaction
            ..insertNode(
                context.node.path.next,
                Node(
                  type: kTableType,
                  attributes: attributes,
                ))
            ..afterSelection = Selection.single(
              path: context.node.path.next,
              startOffset: 0,
            );
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
  late TableData data;

  @override
  void initState() {
    final dataAttr = widget.node.attributes;
    data = dataAttr.isNotEmpty
        ? TableData.fromJson(dataAttr)
        : TableData([
            ['1', '2'],
            ['3', '4']
          ]);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return TableView(
      data: data,
      node: widget.node,
      editorState: widget.editorState,
    );
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
      [Offset.zero & _renderBox.size];

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
