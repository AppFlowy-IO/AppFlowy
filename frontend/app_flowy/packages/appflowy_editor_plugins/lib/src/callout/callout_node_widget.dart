import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';

const String kCalloutType = 'callout';
const String kCalloutAttrColor = 'color';
const String kCalloutAttrEmoji = 'emoji';

SelectionMenuItem calloutMenuItem = SelectionMenuItem(
  name: () => 'Callout',
  icon: (editorState, onSelected) => Icon(
    Icons.note,
    color: onSelected
        ? editorState.editorStyle.selectionMenuItemSelectedIconColor
        : editorState.editorStyle.selectionMenuItemIconColor,
    size: 18.0,
  ),
  keywords: ['callout'],
  handler: (editorState, _, __) {
    final selection =
        editorState.service.selectionService.currentSelection.value;
    final textNodes = editorState.service.selectionService.currentSelectedNodes
        .whereType<TextNode>();
    if (textNodes.length != 1 || selection == null) {
      return;
    }
    final textNode = textNodes.first;
    final node = Node(type: kCalloutType);
    node.insert(TextNode.empty());
    // insert the callout at current path if the text node is empty.
    if (textNode.toPlainText().isEmpty) {
      final transaction = editorState.transaction
        ..insertNode(textNode.path, node)
        ..deleteNode(textNode);
      transaction.afterSelection = selection;
      editorState.apply(transaction);
    } else {
      // insert the callout at the path next to current path if the text node is not empty.
      final transaction = editorState.transaction
        ..insertNode(selection.end.path.next, node);
      editorState.apply(transaction);
    }
  },
);

class CalloutNodeWidgetBuilder extends NodeWidgetBuilder<Node> {
  @override
  Widget build(NodeWidgetContext<Node> context) {
    return _CalloutWidget(
      key: context.node.key,
      node: context.node,
      editorState: context.editorState,
    );
  }

  @override
  NodeValidator<Node> get nodeValidator => (node) => node.type == kCalloutType;
}

class _CalloutWidget extends StatefulWidget {
  const _CalloutWidget({
    super.key,
    required this.node,
    required this.editorState,
  });

  final Node node;
  final EditorState editorState;

  @override
  State<_CalloutWidget> createState() => _CalloutWidgetState();
}

class _CalloutWidgetState extends State<_CalloutWidget> with SelectableMixin {
  RenderBox get _renderBox => context.findRenderObject() as RenderBox;

  @override
  void initState() {
    widget.node.addListener(nodeChanged);
    super.initState();
  }

  @override
  void dispose() {
    widget.node.removeListener(nodeChanged);
    super.dispose();
  }

  void nodeChanged() {
    if (widget.node.children.isEmpty) {
      unlink();
    }
  }

  void unlink() {
    final transaction = widget.editorState.transaction..deleteNode(widget.node);
    widget.editorState.apply(transaction);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.node.attributes[kCalloutAttrColor] as Color?;
    final themeExtension = Theme.of(context).extension<AFThemeExtension>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        color: color ?? themeExtension?.tint1,
      ),
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      child: EditorNodeWidget(
        node: widget.node,
        editorState: widget.editorState,
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
