import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/node_iterator.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/document/state_tree.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/extensions/node_extensions.dart';
import 'package:flowy_editor/render/selection/cursor_widget.dart';
import 'package:flowy_editor/render/selection/selectable.dart';
import 'package:flowy_editor/render/selection/selection_widget.dart';

/// Process selection and cursor
mixin FlowySelectionService<T extends StatefulWidget> on State<T> {
  /// Returns the current [Selection]
  ValueNotifier<Selection?> get currentSelection;

  /// Returns the current selected [Node]s.
  ///
  /// The order of the return is determined according to the selected order.
  List<Node> get currentSelectedNodes;

  /// Update the selection or cursor.
  ///
  /// If selection is collapsed, this method will
  ///   update the position of the cursor.
  /// Otherwise, will update the selection.
  void updateSelection(Selection selection);

  /// Clear the selection or cursor.
  void clearSelection();

  /// ------------------ Selection ------------------------

  List<Rect> rects();

  Position? hitTest(Offset? offset);

  ///
  List<Node> getNodesInSelection(Selection selection);

  /// ------------------ Selection ------------------------

  /// ------------------ Offset ------------------------

  /// Returns selected [Node]s. Empty list would be returned
  ///   if no nodes are being selected.
  ///
  ///
  /// [start] and [end] are the offsets under the global coordinate system.
  ///
  /// If end is not null, it means multiple selection,
  ///   otherwise single selection.
  List<Node> getNodesInRange(Offset start, [Offset? end]);

  /// Return the [Node] or [Null] in single selection.
  ///
  /// [start] is the offset under the global coordinate system.
  Node? computeNodeInOffset(Node node, Offset offset);

  /// Return the [Node]s in multiple selection. Empty list would be returned
  ///   if no nodes are in range.
  ///
  /// [start] is the offset under the global coordinate system.
  List<Node> computeNodesInRange(
    Node node,
    Offset start,
    Offset end,
  );

  /// Return [bool] to identify the [Node] is in Range or not.
  ///
  /// [start] and [end] are the offsets under the global coordinate system.
  bool isNodeInRange(
    Node node,
    Offset start,
    Offset end,
  );

  /// Return [bool] to identify the [Node] contains [Offset] or not.
  ///
  /// [start] is the offset under the global coordinate system.
  bool isNodeInOffset(Node node, Offset offset);

  /// ------------------ Offset ------------------------
}

class FlowySelection extends StatefulWidget {
  const FlowySelection({
    Key? key,
    this.cursorColor = Colors.black,
    this.selectionColor = const Color.fromARGB(60, 61, 61, 213),
    required this.editorState,
    required this.child,
  }) : super(key: key);

  final EditorState editorState;
  final Widget child;
  final Color cursorColor;
  final Color selectionColor;

  @override
  State<FlowySelection> createState() => _FlowySelectionState();
}

class _FlowySelectionState extends State<FlowySelection>
    with FlowySelectionService, WidgetsBindingObserver {
  final _cursorKey = GlobalKey(debugLabel: 'cursor');

  final List<OverlayEntry> _selectionOverlays = [];
  final List<OverlayEntry> _cursorOverlays = [];
  OverlayEntry? _debugOverlay;

  /// [Pan] and [Tap] must be mutually exclusive.
  /// Pan
  Offset? panStartOffset;
  double? panStartScrollDy;
  Offset? panEndOffset;

  /// Tap
  Offset? tapOffset;

  final List<Rect> _rects = [];

  EditorState get editorState => widget.editorState;

  @override
  ValueNotifier<Selection?> currentSelection = ValueNotifier(null);

  @override
  List<Node> currentSelectedNodes = [];

  @override
  List<Node> getNodesInSelection(Selection selection) =>
      _selectedNodesInSelection(editorState.document, selection);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Need to refresh the selection when the metrics changed.
    if (currentSelection.value != null) {
      updateSelection(currentSelection.value!);
    }
  }

  @override
  void dispose() {
    clearSelection();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SelectionGestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTapDown: _onTapDown,
      onDoubleTapDown: _onDoubleTapDown,
      child: widget.child,
    );
  }

  @override
  List<Rect> rects() {
    return _rects;
  }

  @override
  void updateSelection(Selection selection) {
    _rects.clear();
    clearSelection();

    // cursor
    if (selection.isCollapsed) {
      debugPrint('Update cursor');
      _updateCursor(selection.start);
    } else {
      debugPrint('Update selection');
      _updateSelection(selection);
    }
  }

  @override
  void clearSelection() {
    currentSelectedNodes = [];
    currentSelection.value = null;

    // clear selection
    _selectionOverlays
      ..forEach((overlay) => overlay.remove())
      ..clear();
    // clear cursors
    _cursorOverlays
      ..forEach((overlay) => overlay.remove())
      ..clear();
    // clear toolbar
    editorState.service.toolbarService?.hide();
  }

  @override
  List<Node> getNodesInRange(Offset start, [Offset? end]) {
    if (end != null) {
      return computeNodesInRange(editorState.document.root, start, end);
    } else {
      final result = computeNodeInOffset(editorState.document.root, start);
      if (result != null) {
        return [result];
      }
    }
    return [];
  }

  @override
  Node? computeNodeInOffset(Node node, Offset offset) {
    for (final child in node.children) {
      final result = computeNodeInOffset(child, offset);
      if (result != null) {
        return result;
      }
    }
    if (node.parent != null && node.key != null) {
      if (isNodeInOffset(node, offset)) {
        return node;
      }
    }
    return null;
  }

  @override
  List<Node> computeNodesInRange(Node node, Offset start, Offset end) {
    final result = _computeNodesInRange(node, start, end);
    if (start.dy <= end.dy) {
      // downward
      return result;
    } else {
      // upward
      return result.reversed.toList(growable: false);
    }
  }

  List<Node> _computeNodesInRange(Node node, Offset start, Offset end) {
    List<Node> result = [];
    if (node.parent != null && node.key != null) {
      if (isNodeInRange(node, start, end)) {
        result.add(node);
      }
    }
    for (final child in node.children) {
      result.addAll(_computeNodesInRange(child, start, end));
    }
    return result;
  }

  @override
  bool isNodeInOffset(Node node, Offset offset) {
    final renderBox = node.renderBox;
    if (renderBox != null) {
      final boxOffset = renderBox.localToGlobal(Offset.zero);
      final boxRect = boxOffset & renderBox.size;
      return boxRect.contains(offset);
    }
    return false;
  }

  @override
  bool isNodeInRange(Node node, Offset start, Offset end) {
    final renderBox = node.renderBox;
    if (renderBox != null) {
      final rect = Rect.fromPoints(start, end);
      final boxOffset = renderBox.localToGlobal(Offset.zero);
      final boxRect = boxOffset & renderBox.size;
      return rect.overlaps(boxRect);
    }
    return false;
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final offset = details.globalPosition;
    final nodes = getNodesInRange(offset);
    if (nodes.isEmpty) {
      editorState.updateCursorSelection(null);
      return;
    }
    final selectable = nodes.first.selectable;
    if (selectable == null) {
      editorState.updateCursorSelection(null);
      return;
    }
    editorState
        .updateCursorSelection(selectable.getWorldBoundaryInOffset(offset));
  }

  void _onTapDown(TapDownDetails details) {
    // clear old state.
    panStartOffset = null;
    panEndOffset = null;

    tapOffset = details.globalPosition;

    final position = hitTest(tapOffset);
    if (position == null) {
      return;
    }
    final selection = Selection.collapsed(position);
    editorState.updateCursorSelection(selection);
  }

  @override
  Position? hitTest(Offset? offset) {
    if (offset == null) {
      editorState.updateCursorSelection(null);
      return null;
    }
    final nodes = getNodesInRange(offset);
    if (nodes.isEmpty) {
      editorState.updateCursorSelection(null);
      return null;
    }
    assert(nodes.length == 1);
    final selectable = nodes.first.selectable;
    if (selectable == null) {
      editorState.updateCursorSelection(null);
      return null;
    }
    return selectable.getPositionInOffset(offset);
  }

  void _onPanStart(DragStartDetails details) {
    // clear old state.
    panEndOffset = null;
    tapOffset = null;
    clearSelection();

    panStartOffset = details.globalPosition;
    panStartScrollDy = editorState.service.scrollService?.dy;

    debugPrint('[_onPanStart] panStartOffset = $panStartOffset');
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (panStartOffset == null || panStartScrollDy == null) {
      return;
    }

    panEndOffset = details.globalPosition;
    final dy = editorState.service.scrollService?.dy;
    var panStartOffsetWithScrollDyGap = panStartOffset!;
    if (dy != null) {
      panStartOffsetWithScrollDyGap =
          panStartOffsetWithScrollDyGap.translate(0, panStartScrollDy! - dy);
    }

    final sortedNodes =
        editorState.document.root.children.toList(growable: false);
    final first = _lowerBound(
            sortedNodes, panStartOffsetWithScrollDyGap, 0, sortedNodes.length)
        .selectable;
    final last = _upperBound(sortedNodes, panEndOffset!, 0, sortedNodes.length)
        .selectable;

    // compute the selection in range.
    if (first != null && last != null) {
      bool isDownward;
      if (first == last) {
        isDownward = panStartOffsetWithScrollDyGap.dx < panEndOffset!.dx;
      } else {
        isDownward = panStartOffsetWithScrollDyGap.dy < panEndOffset!.dy;
      }
      final start = first
          .getSelectionInRange(panStartOffsetWithScrollDyGap, panEndOffset!)
          .start;
      final end = last
          .getSelectionInRange(panStartOffsetWithScrollDyGap, panEndOffset!)
          .end;
      final selection = Selection(
          start: isDownward ? start : end, end: isDownward ? end : start);
      debugPrint('[_onPanUpdate] isDownward = $isDownward, $selection');
      editorState.updateCursorSelection(selection);
    }

    _scrollUpOrDownIfNeeded(panEndOffset!);
    _showDebugLayerIfNeeded();
  }

  void _onPanEnd(DragEndDetails details) {
    // do nothing
  }

  void _updateSelection(Selection selection) {
    final nodes = _selectedNodesInSelection(editorState.document, selection);

    currentSelectedNodes = nodes;
    currentSelection.value = selection;

    Rect? topmostRect;
    LayerLink? layerLink;

    var index = 0;
    for (final node in nodes) {
      final selectable = node.selectable;
      if (selectable == null) {
        continue;
      }

      var newSelection = selection.copy();
      // In the case of multiple selections,
      //  we need to return a new selection for each selected node individually.
      if (!selection.isSingle) {
        // <> means selected.
        // text: abcd<ef
        // text: ghijkl
        // text: mn>opqr
        if (index == 0) {
          if (selection.isDownward) {
            newSelection = selection.copyWith(end: selectable.end());
          } else {
            newSelection = selection.copyWith(start: selectable.start());
          }
        } else if (index == nodes.length - 1) {
          if (selection.isDownward) {
            newSelection = selection.copyWith(start: selectable.start());
          } else {
            newSelection = selection.copyWith(end: selectable.end());
          }
        } else {
          newSelection = selection.copyWith(
            start: selectable.start(),
            end: selectable.end(),
          );
        }
      }

      final rects = selectable.getRectsInSelection(newSelection);

      for (final rect in rects) {
        // FIXME: Need to compute more precise location.
        topmostRect ??= rect;
        layerLink ??= node.layerLink;

        _rects.add(_transformRectToGlobal(selectable, rect));
        final overlay = OverlayEntry(
          builder: (context) => SelectionWidget(
            color: widget.selectionColor,
            layerLink: node.layerLink,
            rect: rect,
          ),
        );
        _selectionOverlays.add(overlay);
      }
      index += 1;
    }
    Overlay.of(context)?.insertAll(_selectionOverlays);

    if (topmostRect != null && layerLink != null) {
      editorState.service.toolbarService
          ?.showInOffset(topmostRect.topLeft, layerLink);
    }
  }

  Rect _transformRectToGlobal(Selectable selectable, Rect r) {
    final Offset topLeft = selectable.localToGlobal(Offset(r.left, r.top));
    return Rect.fromLTWH(topLeft.dx, topLeft.dy, r.width, r.height);
  }

  void _updateCursor(Position position) {
    final node = editorState.document.root.childAtPath(position.path);

    assert(node != null);
    if (node == null) {
      return;
    }

    currentSelectedNodes = [node];
    currentSelection.value = Selection.collapsed(position);

    final selectable = node.selectable;
    final rect = selectable?.getCursorRectInPosition(position);
    if (rect != null) {
      _rects.add(_transformRectToGlobal(selectable!, rect));
      final cursor = OverlayEntry(
        builder: (context) => CursorWidget(
          key: _cursorKey,
          rect: rect,
          color: widget.cursorColor,
          layerLink: node.layerLink,
        ),
      );
      _cursorOverlays.add(cursor);
      Overlay.of(context)?.insertAll(_cursorOverlays);
      _forceShowCursor();
    }
  }

  _forceShowCursor() {
    final currentState = _cursorKey.currentState as CursorWidgetState?;
    currentState?.show();
  }

  List<Node> _selectedNodesInSelection(
      StateTree stateTree, Selection selection) {
    final startNode = stateTree.nodeAtPath(selection.start.path)!;
    final endNode = stateTree.nodeAtPath(selection.end.path)!;
    return NodeIterator(stateTree, startNode, endNode).toList();
  }

  void _scrollUpOrDownIfNeeded(Offset offset) {
    final dy = editorState.service.scrollService?.dy;
    if (dy == null) {
      assert(false, 'Dy could not be null');
      return;
    }
    final topLimit = MediaQuery.of(context).size.height * 0.2;
    final bottomLimit = MediaQuery.of(context).size.height * 0.8;

    /// TODO: It is necessary to calculate the relative speed
    ///   according to the gap and move forward more gently.
    final distance = 10.0;
    if (offset.dy <= topLimit) {
      // up
      editorState.service.scrollService?.scrollTo(dy - distance);
    } else if (offset.dy >= bottomLimit) {
      //down
      editorState.service.scrollService?.scrollTo(dy + distance);
    }
  }

  void _showDebugLayerIfNeeded() {
    // remove false to show debug overlay.
    if (kDebugMode && false) {
      _debugOverlay?.remove();
      if (panStartOffset != null) {
        _debugOverlay = OverlayEntry(
          builder: (context) => Positioned.fromRect(
            rect: Rect.fromPoints(
                    panStartOffset?.translate(
                          0,
                          -(editorState.service.scrollService!.dy -
                              panStartScrollDy!),
                        ) ??
                        Offset.zero,
                    panEndOffset ?? Offset.zero)
                .translate(0, 0),
            child: Container(
              color: Colors.red.withOpacity(0.2),
            ),
          ),
        );
        Overlay.of(context)?.insert(_debugOverlay!);
      } else {
        _debugOverlay = null;
      }
    }
  }

  // find the first node's rect.top <= offset.dy
  Node _lowerBound(List<Node> sortedNodes, Offset offset, int start, int end) {
    var min = start;
    var max = end;
    while (min <= max) {
      final mid = min + ((max - min) >> 1);
      if (sortedNodes[mid].rect.bottom <= offset.dy) {
        min = mid + 1;
      } else {
        max = mid - 1;
      }
    }
    return sortedNodes[min];
  }

  // find the first node's rect.top < offset.dy
  Node _upperBound(
    List<Node> sortedNodes,
    Offset offset,
    int start,
    int end,
  ) {
    var min = start;
    var max = end;
    while (min <= max) {
      final mid = min + ((max - min) >> 1);
      if (sortedNodes[mid].rect.top < offset.dy) {
        min = mid + 1;
      } else {
        max = mid - 1;
      }
    }
    return sortedNodes[max];
  }
}

/// Because the flutter's [DoubleTapGestureRecognizer] will block the [TapGestureRecognizer]
/// for a while. So we need to implement our own GestureDetector.
@immutable
class _SelectionGestureDetector extends StatefulWidget {
  const _SelectionGestureDetector(
      {Key? key,
      this.child,
      this.onTapDown,
      this.onDoubleTapDown,
      this.onPanStart,
      this.onPanUpdate,
      this.onPanEnd})
      : super(key: key);

  @override
  State<_SelectionGestureDetector> createState() =>
      _SelectionGestureDetectorState();

  final Widget? child;

  final GestureTapDownCallback? onTapDown;
  final GestureTapDownCallback? onDoubleTapDown;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
}

class _SelectionGestureDetectorState extends State<_SelectionGestureDetector> {
  bool _isDoubleTap = false;
  Timer? _doubleTapTimer;
  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: {
        PanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(),
          (recognizer) {
            recognizer
              ..onStart = widget.onPanStart
              ..onUpdate = widget.onPanUpdate
              ..onEnd = widget.onPanEnd;
          },
        ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (recognizer) {
            recognizer.onTapDown = _tapDownDelegate;
          },
        ),
      },
      child: widget.child,
    );
  }

  _tapDownDelegate(TapDownDetails tapDownDetails) {
    if (_isDoubleTap) {
      _isDoubleTap = false;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = null;
      if (widget.onDoubleTapDown != null) {
        widget.onDoubleTapDown!(tapDownDetails);
      }
    } else {
      if (widget.onTapDown != null) {
        widget.onTapDown!(tapDownDetails);
      }

      _isDoubleTap = true;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = Timer(kDoubleTapTimeout, () {
        _isDoubleTap = false;
        _doubleTapTimer = null;
      });
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    super.dispose();
  }
}
