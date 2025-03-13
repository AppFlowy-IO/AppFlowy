import 'dart:math';

import 'package:appflowy/plugins/document/presentation/editor_plugins/columns/simple_columns_block_constant.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// if the children is not provided, it will create two columns by default.
// if the columnCount is provided, it will create the specified number of columns.
Node simpleColumnsNode({
  List<Node>? children,
  int? columnCount,
  double? ratio,
}) {
  columnCount ??= 2;
  children ??= List.generate(
    columnCount,
    (index) => simpleColumnNode(
      ratio: ratio,
      children: [paragraphNode()],
    ),
  );

  // check the type of children
  for (final child in children) {
    if (child.type != SimpleColumnBlockKeys.type) {
      Log.error('the type of children must be column, but got ${child.type}');
    }
  }

  return Node(
    type: SimpleColumnsBlockKeys.type,
    children: children,
  );
}

class SimpleColumnsBlockKeys {
  const SimpleColumnsBlockKeys._();

  static const String type = 'simple_columns';
}

class SimpleColumnsBlockComponentBuilder extends BlockComponentBuilder {
  SimpleColumnsBlockComponentBuilder({super.configuration});

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return ColumnsBlockComponent(
      key: node.key,
      node: node,
      showActions: showActions(node),
      configuration: configuration,
      actionBuilder: (_, state) => actionBuilder(blockComponentContext, state),
    );
  }

  @override
  BlockComponentValidate get validate => (node) => node.children.isNotEmpty;
}

class ColumnsBlockComponent extends BlockComponentStatefulWidget {
  const ColumnsBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<ColumnsBlockComponent> createState() => ColumnsBlockComponentState();
}

class ColumnsBlockComponentState extends State<ColumnsBlockComponent>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  final columnsKey = GlobalKey();

  late final EditorState editorState = context.read<EditorState>();

  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _updateColumnsBlock();
  }

  @override
  void dispose() {
    scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _buildChildren(),
    );

    child = Align(
      alignment: Alignment.topLeft,
      child: IntrinsicHeight(
        child: child,
      ),
    );

    child = Padding(
      key: columnsKey,
      padding: padding,
      child: child,
    );

    if (SimpleColumnsBlockConstants.enableDebugBorder) {
      child = DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.red,
            width: 3.0,
          ),
        ),
        child: child,
      );
    }

    // the columns block does not support the block actions and selection
    // because the columns block is a layout wrapper, it does not have a content
    return child;
  }

  List<Widget> _buildChildren() {
    final length = node.children.length;
    final children = <Widget>[];
    for (var i = 0; i < length; i++) {
      final childNode = node.children[i];
      final double ratio =
          childNode.attributes[SimpleColumnBlockKeys.ratio]?.toDouble() ??
              1.0 / length;

      Widget child = editorState.renderer.build(context, childNode);

      child = Expanded(
        flex: (max(ratio, 0.1) * 10000).toInt(),
        child: child,
      );

      children.add(child);

      if (i != length - 1) {
        children.add(
          SimpleColumnBlockWidthResizer(
            columnNode: childNode,
            editorState: editorState,
          ),
        );
      }
    }
    return children;
  }

  // Update the existing columns block data
  // if the column ratio is not existing, it will be set to 1.0 / columnCount
  void _updateColumnsBlock() {
    final transaction = editorState.transaction;
    final length = node.children.length;
    for (int i = 0; i < length; i++) {
      final childNode = node.children[i];
      final ratio = childNode.attributes[SimpleColumnBlockKeys.ratio];
      if (ratio == null) {
        transaction.updateNode(childNode, {
          ...childNode.attributes,
          SimpleColumnBlockKeys.ratio: 1.0 / length,
        });
      }
    }
    if (transaction.operations.isNotEmpty) {
      editorState.apply(transaction);
    }
  }

  @override
  Position start() => Position(path: widget.node.path);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({
    bool shiftWithBaseOffset = false,
  }) {
    return getRectsInSelection(Selection.invalid()).first;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    final rects = getRectsInSelection(
      Selection.collapsed(position),
      shiftWithBaseOffset: shiftWithBaseOffset,
    );
    return rects.firstOrNull;
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    if (_renderBox == null) {
      return [];
    }
    final parentBox = context.findRenderObject();
    final renderBox = columnsKey.currentContext?.findRenderObject();
    if (parentBox is RenderBox && renderBox is RenderBox) {
      return [
        renderBox.localToGlobal(Offset.zero, ancestor: parentBox) &
            renderBox.size,
      ];
    }
    return [Offset.zero & _renderBox!.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) =>
      Selection.single(path: widget.node.path, startOffset: 0, endOffset: 1);

  @override
  Offset localToGlobal(Offset offset, {bool shiftWithBaseOffset = false}) =>
      _renderBox!.localToGlobal(offset);
}
