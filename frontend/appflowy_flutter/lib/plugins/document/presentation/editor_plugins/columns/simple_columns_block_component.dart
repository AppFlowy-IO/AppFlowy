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
  double? width,
}) {
  columnCount ??= 2;
  children ??= List.generate(
    columnCount,
    (index) => simpleColumnNode(
      width: width,
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

  ValueNotifier<double?> maxEditorWidth = ValueNotifier(null);

  @override
  void dispose() {
    scrollController.dispose();
    maxEditorWidth.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child = ValueListenableBuilder<double?>(
      valueListenable: maxEditorWidth,
      builder: (context, maxEditorWidth, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _buildChildren(maxEditorWidth: maxEditorWidth),
        );
      },
    );

    // if (UniversalPlatform.isDesktop) {
    //   // only show the scrollbar on desktop
    //   child = Scrollbar(
    //     controller: scrollController,
    //     child: child,
    //   );
    // }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        maxEditorWidth.value = constraints.maxWidth;
        return child;
      },
    );
  }

  List<Widget> _buildChildren({double? maxEditorWidth}) {
    final sumWidth = node.children.fold<double>(
      0,
      (sum, child) =>
          sum +
          (child.attributes[SimpleColumnBlockKeys.width]?.toDouble() ??
              SimpleColumnsBlockConstants.minimumColumnWidth),
    );
    final children = <Widget>[];
    for (var i = 0; i < node.children.length; i++) {
      final childNode = node.children[i];
      double width =
          childNode.attributes[SimpleColumnBlockKeys.width]?.toDouble() ??
              SimpleColumnsBlockConstants.minimumColumnWidth;
      if (maxEditorWidth != null) {
        width =
            width * (maxEditorWidth - (node.children.length) * 6) / sumWidth;
      }
      Widget child = editorState.renderer.build(context, childNode);

      child = SizedBox(
        width: width.clamp(
          SimpleColumnsBlockConstants.minimumColumnWidth,
          double.infinity,
        ),
        child: child,
      );

      children.add(child);

      children.add(
        SimpleColumnBlockWidthResizer(
          columnNode: childNode,
          editorState: editorState,
        ),
      );
    }
    return children;
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
