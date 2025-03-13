import 'package:appflowy/plugins/document/presentation/editor_plugins/columns/simple_columns_block_constant.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Node simpleColumnNode({
  List<Node>? children,
  double? ratio,
}) {
  return Node(
    type: SimpleColumnBlockKeys.type,
    children: children ?? [paragraphNode()],
    attributes: {
      SimpleColumnBlockKeys.ratio: ratio,
    },
  );
}

extension SimpleColumnBlockAttributes on Node {
  // get the next column node of the current column node
  // if the current column node is the last column node, return null
  Node? get nextColumn {
    final index = path.last;
    final parent = this.parent;
    if (parent == null || index == parent.children.length - 1) {
      return null;
    }
    return parent.children[index + 1];
  }

  // get the previous column node of the current column node
  // if the current column node is the first column node, return null
  Node? get previousColumn {
    final index = path.last;
    final parent = this.parent;
    if (parent == null || index == 0) {
      return null;
    }
    return parent.children[index - 1];
  }
}

class SimpleColumnBlockKeys {
  const SimpleColumnBlockKeys._();

  static const String type = 'simple_column';

  /// @Deprecated Use [SimpleColumnBlockKeys.ratio] instead.
  ///
  /// This field is no longer used since v0.6.9
  @Deprecated('Use [SimpleColumnBlockKeys.ratio] instead.')
  static const String width = 'width';

  /// The ratio of the column width.
  ///
  /// The value is a double number between 0 and 1.
  static const String ratio = 'ratio';
}

class SimpleColumnBlockComponentBuilder extends BlockComponentBuilder {
  SimpleColumnBlockComponentBuilder({
    super.configuration,
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return SimpleColumnBlockComponent(
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

class SimpleColumnBlockComponent extends BlockComponentStatefulWidget {
  const SimpleColumnBlockComponent({
    super.key,
    required super.node,
    super.showActions,
    super.actionBuilder,
    super.actionTrailingBuilder,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<SimpleColumnBlockComponent> createState() =>
      SimpleColumnBlockComponentState();
}

class SimpleColumnBlockComponentState extends State<SimpleColumnBlockComponent>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  final columnKey = GlobalKey();

  late final EditorState editorState = context.read<EditorState>();

  @override
  Widget build(BuildContext context) {
    Widget child = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: node.children.map(
        (e) {
          Widget child = IntrinsicHeight(
            child: editorState.renderer.build(context, e),
          );
          if (e.type == CustomImageBlockKeys.type) {
            child = IntrinsicWidth(child: child);
          }
          if (SimpleColumnsBlockConstants.enableDebugBorder) {
            child = DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.blue,
                ),
              ),
              child: child,
            );
          }
          return child;
        },
      ).toList(),
    );

    child = Padding(
      key: columnKey,
      padding: padding,
      child: child,
    );

    if (SimpleColumnsBlockConstants.enableDebugBorder) {
      child = Container(
        color: Colors.green.withValues(
          alpha: 0.3,
        ),
        child: child,
      );
    }

    // the column block does not support the block actions and selection
    // because the column block is a layout wrapper, it does not have a content
    return child;
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
    final renderBox = columnKey.currentContext?.findRenderObject();
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
