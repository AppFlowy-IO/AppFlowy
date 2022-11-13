import 'dart:collection';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

ShortcutEvent insertHorizontalRule = ShortcutEvent(
  key: 'Horizontal rule',
  command: 'Minus',
  handler: _insertHorzaontalRule,
);

ShortcutEventHandler _insertHorzaontalRule = (editorState, event) {
  final selection = editorState.service.selectionService.currentSelection.value;
  final textNodes = editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  if (textNodes.length != 1 || selection == null) {
    return KeyEventResult.ignored;
  }
  final textNode = textNodes.first;
  if (textNode.toPlainText() == '--') {
    final transaction = editorState.transaction
      ..deleteText(textNode, 0, 2)
      ..insertNode(
        textNode.path,
        Node(
          type: 'horizontal_rule',
          children: LinkedList(),
          attributes: {},
        ),
      )
      ..afterSelection =
          Selection.single(path: textNode.path.next, startOffset: 0);
    editorState.apply(transaction);
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

SelectionMenuItem horizontalRuleMenuItem = SelectionMenuItem(
  name: () => 'Horizontal rule',
  icon: (_, __) => const Icon(
    Icons.horizontal_rule,
    color: Colors.black,
    size: 18.0,
  ),
  keywords: ['horizontal rule'],
  handler: (editorState, _, __) {
    final selection =
        editorState.service.selectionService.currentSelection.value;
    final textNodes = editorState.service.selectionService.currentSelectedNodes
        .whereType<TextNode>();
    if (selection == null || textNodes.isEmpty) {
      return;
    }
    final textNode = textNodes.first;
    if (textNode.toPlainText().isEmpty) {
      final transaction = editorState.transaction
        ..insertNode(
          textNode.path,
          Node(
            type: 'horizontal_rule',
            children: LinkedList(),
            attributes: {},
          ),
        )
        ..afterSelection =
            Selection.single(path: textNode.path.next, startOffset: 0);
      editorState.apply(transaction);
    } else {
      final transaction = editorState.transaction
        ..insertNode(
          selection.end.path.next,
          TextNode(
            children: LinkedList(),
            attributes: {
              'subtype': 'horizontal_rule',
            },
            delta: Delta()..insert('---'),
          ),
        )
        ..afterSelection = selection;
      editorState.apply(transaction);
    }
  },
);

class HorizontalRuleWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _HorizontalRuleWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) {
        return true;
      };
}

class _HorizontalRuleWidget extends StatefulWidget {
  const _HorizontalRuleWidget({
    Key? key,
    required this.node,
    required this.editorState,
  }) : super(key: key);

  final Node node;
  final EditorState editorState;

  @override
  State<_HorizontalRuleWidget> createState() => __HorizontalRuleWidgetState();
}

class __HorizontalRuleWidgetState extends State<_HorizontalRuleWidget>
    with SelectableMixin {
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        height: 1,
        color: Colors.grey,
      ),
    );
  }

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.borderLine;

  @override
  Rect? getCursorRectInPosition(Position position) {
    final size = _renderBox.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

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
  Offset localToGlobal(Offset offset) => _renderBox.localToGlobal(offset);
}
