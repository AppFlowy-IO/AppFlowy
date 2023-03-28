import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

abstract class SelectionService {
  Selection? selection;

  void addListenr(VoidCallback listener);
  void removeListerner(VoidCallback listener);

  Node? getNodeInOffset(Offset offset);
}

abstract class ScrollService {
  Offset get offset;

  Future<void> scrollTo(Offset offset);
}

class SelectionAndScroll extends StatefulWidget {
  const SelectionAndScroll({
    super.key,
    required this.nodes,
  });

  final List<Node> nodes;

  @override
  State<SelectionAndScroll> createState() => _SelectionAndScrollState();
}

class _SelectionAndScrollState extends State<SelectionAndScroll>
    with WidgetsBindingObserver
    implements SelectionService, ScrollService {
  //
  ScrollableState? scrollableState;
  final ValueNotifier<Selection?> _selection = ValueNotifier(null);
  final Set<Node> visibleNodes = {};

  Position? _startPosition;
  Position? _endPosition;

  List<Node> get nodes => widget.nodes;
  EditorState get editorState => Provider.of<EditorState>(context);

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
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onTapDown: _onTapDown,
      child: ListView.builder(
        itemBuilder: (context, index) {
          // TODO: Any good ideas to get the scrollableState?
          scrollableState ??= Scrollable.of(context);

          // build child
          final node = nodes[index];
          final child = _buildChild(context, node);
          return _SelectionWrapper(
            onCreate: () => visibleNodes.add(node),
            onDispose: () => visibleNodes.remove(node),
            child: child,
          );
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
  void dispose() {
    visibleNodes.clear();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void addListenr(VoidCallback listener) {
    _selection.addListener(listener);
  }

  @override
  void removeListerner(VoidCallback listener) {
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
    if (node.children.isNotEmpty && node.children.first.rect.top <= offset.dy) {
      final children = node.children.toList(growable: false);
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
    final node = getNodeInOffset(details.globalPosition);
    final selectable = node?.selectableV2;
    if (selectable != null) {
      _startPosition = selectable.getPositionInOffset(details.globalPosition);
    }
    assert(_startPosition != null);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final node = getNodeInOffset(details.globalPosition);
    final selectable = node?.selectableV2;
    if (selectable != null && _startPosition != null) {
      _endPosition = selectable.getPositionInOffset(details.globalPosition);
      _selection.value = Selection(
        start: _startPosition!,
        end: _endPosition!,
      );
    }
    assert(_endPosition != null);
  }

  void _onTapDown(TapDownDetails details) {
    final node = getNodeInOffset(details.globalPosition);
    final selectable = node?.selectableV2;
    if (selectable != null) {
      _startPosition = selectable.getPositionInOffset(details.globalPosition);
      _endPosition = _startPosition?.copyWith();
      _selection.value = Selection(
        start: _startPosition!,
        end: _endPosition!,
      );
    }
    assert(_startPosition != null);
  }

  void _updateVisibleNodesSelection(Selection selection) {
    for (final node in visibleNodes) {
      final selectable = node.selectableV2;
      if (selectable != null) {
        selectable.setSelectionV2(selection);
      }
    }
  }
}

class _SelectionWrapper extends StatefulWidget {
  const _SelectionWrapper({
    required this.onCreate,
    required this.onDispose,
    required this.child,
  });

  final VoidCallback onCreate;
  final VoidCallback onDispose;
  final Widget child;

  @override
  State<_SelectionWrapper> createState() => __SelectionWrapperState();
}

class __SelectionWrapperState extends State<_SelectionWrapper> {
  @override
  Widget build(BuildContext context) {
    widget.onCreate();
    return widget.child;
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }
}
