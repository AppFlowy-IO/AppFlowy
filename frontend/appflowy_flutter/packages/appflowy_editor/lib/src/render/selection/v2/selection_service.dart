import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

abstract class SelectionService {
  Selection? selection;
  Set<Node> get visibleNodes;

  void addListener(VoidCallback listener);
  void removeListener(VoidCallback listener);

  Node? getNodeInOffset(Offset offset);
}

abstract class ScrollService {
  Offset get offset;

  Future<void> scrollTo(Offset offset);

  ScrollController get scrollController;
}

class SelectionAndScroll extends StatefulWidget {
  const SelectionAndScroll({
    super.key,
  });

  @override
  State<SelectionAndScroll> createState() => _SelectionAndScrollState();
}

class _SelectionAndScrollState extends State<SelectionAndScroll>
    with WidgetsBindingObserver
    implements SelectionService, ScrollService {
  // Scroll
  @override
  ScrollableState? scrollableState;
  EdgeDraggingAutoScroller? scroller;
  @override
  final ScrollController scrollController = ScrollController();

  // Selection
  final ValueNotifier<Selection?> _selection = ValueNotifier(null);
  @override
  final Set<Node> visibleNodes = {};

  Position? _startPosition;
  Position? _endPosition;

  List<Node> nodes = [];
  late EditorState editorState;

  @override
  Selection? get selection {
    return _selection.value;
  }

  @override
  set selection(Selection? selection) {
    _selection.value = selection;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    editorState = Provider.of<EditorState>(context, listen: false);
    // Not a good idea to rebuild the whole list when the root changes.
    {
      nodes = editorState.document.root.children.toList(growable: false);
      editorState.document.root.addListener(_updateNodes);
    }
  }

  @override
  void dispose() {
    {
      editorState.document.root.removeListener(_updateNodes);
    }
    visibleNodes.clear();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onTapDown: _onTapDown,
      child: ListView.builder(
        controller: scrollController,
        itemBuilder: (context, index) {
          // TODO: Any good ideas to get the scrollableState?
          _initScrollServiceIfNeed(context);

          // build child
          final node = nodes[index];
          final child = _buildChild(context, node);
          return child;
        },
        itemCount: nodes.length,
      ),
    );
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Need to refresh the selection when the metrics changed.
    if (selection != null) {
      _selection.value = selection;
      // optimize it.
      _selection.notifyListeners();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    _selection.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _selection.removeListener(listener);
  }

  @override
  Node? getNodeInOffset(Offset offset) {
    if (visibleNodes.isEmpty) {
      return null;
    }
    //
    final sortedNodes = visibleNodes.toList(growable: false)
      ..sort((a, b) => a.rect.top.compareTo(b.rect.top));
    return _binarySearchNode(
      sortedNodes,
      offset,
      0,
      sortedNodes.length - 1,
    );
  }

  @override
  Future<void> scrollTo(Offset offset) {
    throw UnimplementedError();
  }

  @override
  // TODO: implement offset
  Offset get offset => throw UnimplementedError();

  Widget _buildChild(BuildContext context, Node node) {
    // remove this editorState, we should use it though provider.
    final editorState = Provider.of<EditorState>(context);
    return editorState.service.renderPluginService.buildPluginWidget(
      node is TextNode
          ? NodeWidgetContext<TextNode>(
              context: context,
              node: node,
              editorState: editorState,
            )
          : NodeWidgetContext<Node>(
              context: context,
              node: node,
              editorState: editorState,
            ),
    );
  }

  void _updateNodes() {
    setState(() {
      nodes = editorState.document.root.children.toList(growable: false);
    });
  }

  Node? _binarySearchNode(
    List<Node> sortedNodes,
    Offset offset,
    int start,
    int end,
  ) {
    if (start < 0 && end >= sortedNodes.length) {
      return null;
    }
    var min = start;
    var max = end;
    while (min <= max) {
      final mid = min + ((max - min) >> 1);
      final rect = sortedNodes[mid].rect;
      if (rect.bottom <= offset.dy) {
        min = mid + 1;
      } else {
        max = mid - 1;
      }
    }
    min = min.clamp(start, end);
    final node = sortedNodes[min];
    final children = node.children.toList(growable: false);
    if (children.isNotEmpty && children.first.rect.top <= offset.dy) {
      return _binarySearchNode(
        children,
        offset,
        0,
        children.length - 1,
      );
    }
    return node;
  }

  void _onPanStart(DragStartDetails details) {
    _startPosition = _getPositionInOffset(details.globalPosition);
    assert(_startPosition != null);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _endPosition = _getPositionInOffset(details.globalPosition);
    if (_startPosition == null || _endPosition == null) {
      return;
    }
    _selection.value = Selection(
      start: _startPosition!,
      end: _endPosition!,
    );
    _startAutoScrollIfNecessary(details.globalPosition);
  }

  void _onTapDown(TapDownDetails details) {
    _startPosition = _getPositionInOffset(details.globalPosition);
    assert(_startPosition != null);
    if (_startPosition == null) {
      return;
    }
    _endPosition = _startPosition?.copyWith();
    _selection.value = Selection(
      start: _startPosition!,
      end: _endPosition!,
    );
    _startAutoScrollIfNecessary(details.globalPosition);
  }

  Position? _getPositionInOffset(Offset offset) {
    final node = getNodeInOffset(offset);
    final selectable = node?.selectableV2;
    return selectable?.getPositionInOffset(offset);
  }

  void _initScrollServiceIfNeed(BuildContext context) {
    scrollableState ??= Scrollable.of(context);
    scroller ??= EdgeDraggingAutoScroller(
      scrollableState!,
      velocityScalar: 30,
      onScrollViewScrolled: () {},
    );
  }

  void _startAutoScrollIfNecessary(Offset offset) {
    final rect = Rect.fromCenter(center: offset, width: 200, height: 200);
    scroller?.startAutoScrollIfNecessary(rect);
  }

  void _refresh() {
    setState(() {});
  }
}
