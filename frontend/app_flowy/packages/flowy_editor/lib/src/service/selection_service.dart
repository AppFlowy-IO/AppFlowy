import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:flowy_editor/src/document/node.dart';
import 'package:flowy_editor/src/document/node_iterator.dart';
import 'package:flowy_editor/src/document/position.dart';
import 'package:flowy_editor/src/document/selection.dart';
import 'package:flowy_editor/src/document/state_tree.dart';
import 'package:flowy_editor/src/editor_state.dart';
import 'package:flowy_editor/src/extensions/node_extensions.dart';
import 'package:flowy_editor/src/render/selection/cursor_widget.dart';
import 'package:flowy_editor/src/render/selection/selectable.dart';
import 'package:flowy_editor/src/render/selection/selection_widget.dart';

/// [FlowySelectionService] is responsible for processing
/// the [Selection] changes and updates.
///
/// Usually, this service can be obtained by the following code.
/// ```dart
/// final selectionService = editorState.service.selectionService;
///
/// /** get current selection value*/
/// final selection = selectionService.currentSelection.value;
///
/// /** get current selected nodes*/
/// final nodes = selectionService.currentSelectedNodes;
/// ```
///
mixin FlowySelectionService<T extends StatefulWidget> on State<T> {
  /// The current [Selection] in editor.
  ///
  /// The value is null if there is no nodes are selected.
  ValueNotifier<Selection?> get currentSelection;

  /// The current selected [Node]s in editor.
  ///
  /// The order of the result is determined according to the [currentSelection].
  /// The result are ordered from back to front if the selection is forward.
  /// The result are ordered from front to back if the selection is backward.
  ///
  /// For example, Here is an array of selected nodes, [n1, n2, n3].
  /// The result will be [n3, n2, n1] if the selection is forward,
  ///   and [n1, n2, n3] if the selection is backward.
  ///
  /// Returns empty result if there is no nodes are selected.
  List<Node> get currentSelectedNodes;

  /// Updates the selection.
  ///
  /// The editor will update selection area and popup list area
  /// if the [selection] is not collapsed,
  /// otherwise, will update the cursor area.
  void updateSelection(Selection selection);

  /// Clears the selection area, cursor area and the popup list area.
  void clearSelection();

  /// Returns the [Node]s in [Selection].
  List<Node> getNodesInSelection(Selection selection);

  /// Returns the [Node] containing to the offset.
  ///
  /// [offset] must be under the global coordinate system.
  Node? getNodeInOffset(Offset offset);

  // TODO: need to be documented.
  List<Rect> rects();
  Position? hitTest(Offset? offset);
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
      onTripleTapDown: _onTripleTapDown,
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
  Node? getNodeInOffset(Offset offset) {
    return _lowerBoundInDocument(offset);
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final offset = details.globalPosition;
    final node = getNodeInOffset(offset);
    if (node == null) {
      editorState.updateCursorSelection(null);
      return;
    }
    final selectable = node.selectable;
    if (selectable == null) {
      editorState.updateCursorSelection(null);
      return;
    }
    editorState
        .updateCursorSelection(selectable.getWorldBoundaryInOffset(offset));
  }

  void _onTripleTapDown(TapDownDetails details) {
    final offset = details.globalPosition;
    final node = getNodeInOffset(offset);
    if (node == null) {
      editorState.updateCursorSelection(null);
      return;
    }
    Selection selection;
    if (node is TextNode) {
      final textLen = node.delta.length;
      selection = Selection(
          start: Position(path: node.path, offset: 0),
          end: Position(path: node.path, offset: textLen));
    } else {
      selection = Selection.collapsed(Position(path: node.path, offset: 0));
    }
    editorState.updateCursorSelection(selection);
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

    editorState.service.keyboardService?.enable();
    editorState.service.scrollService?.enable();
  }

  @override
  Position? hitTest(Offset? offset) {
    if (offset == null) {
      editorState.updateCursorSelection(null);
      return null;
    }
    final node = getNodeInOffset(offset);
    if (node == null) {
      editorState.updateCursorSelection(null);
      return null;
    }
    final selectable = node.selectable;
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

    editorState.service.keyboardService?.enable();
    editorState.service.scrollService?.enable();

    panEndOffset = details.globalPosition;
    final dy = editorState.service.scrollService?.dy;
    var panStartOffsetWithScrollDyGap = panStartOffset!;
    if (dy != null) {
      panStartOffsetWithScrollDyGap =
          panStartOffsetWithScrollDyGap.translate(0, panStartScrollDy! - dy);
    }

    final first =
        _lowerBoundInDocument(panStartOffsetWithScrollDyGap).selectable;
    final last = _upperBoundInDocument(panEndOffset!).selectable;

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

      _scrollUpOrDownIfNeeded(panEndOffset!, isDownward);
    }

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
          if (selection.isBackward) {
            newSelection = selection.copyWith(end: selectable.end());
          } else {
            newSelection = selection.copyWith(start: selectable.start());
          }
        } else if (index == nodes.length - 1) {
          if (selection.isBackward) {
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

  void _scrollUpOrDownIfNeeded(Offset offset, bool isDownward) {
    final dy = editorState.service.scrollService?.dy;
    if (dy == null) {
      assert(false, 'Dy could not be null');
      return;
    }
    final topLimit = MediaQuery.of(context).size.height * 0.2;
    final bottomLimit = MediaQuery.of(context).size.height * 0.8;

    /// TODO: It is necessary to calculate the relative speed
    ///   according to the gap and move forward more gently.
    const distance = 10.0;
    if (offset.dy <= topLimit && !isDownward) {
      // up
      editorState.service.scrollService?.scrollTo(dy - distance);
    } else if (offset.dy >= bottomLimit && isDownward) {
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

  Node _lowerBoundInDocument(Offset offset) {
    final sortedNodes =
        editorState.document.root.children.toList(growable: false);
    return _lowerBound(sortedNodes, offset, 0, sortedNodes.length - 1);
  }

  Node _upperBoundInDocument(Offset offset) {
    final sortedNodes =
        editorState.document.root.children.toList(growable: false);
    return _upperBound(sortedNodes, offset, 0, sortedNodes.length - 1);
  }

  /// TODO: Supports multi-level nesting,
  ///  currently only single-level nesting is supported
  // find the first node's rect.bottom <= offset.dy
  Node _lowerBound(List<Node> sortedNodes, Offset offset, int start, int end) {
    assert(start >= 0 && end < sortedNodes.length);
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
    final node = sortedNodes[min];
    if (node.children.isNotEmpty && node.children.first.rect.top <= offset.dy) {
      final children = node.children.toList(growable: false);
      return _lowerBound(children, offset, 0, children.length - 1);
    }
    return node;
  }

  /// TODO: Supports multi-level nesting,
  ///  currently only single-level nesting is supported
  // find the first node's rect.top < offset.dy
  Node _upperBound(
    List<Node> sortedNodes,
    Offset offset,
    int start,
    int end,
  ) {
    assert(start >= 0 && end < sortedNodes.length);
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
    final node = sortedNodes[max];
    if (node.children.isNotEmpty && node.children.first.rect.top <= offset.dy) {
      final children = node.children.toList(growable: false);
      return _lowerBound(children, offset, 0, children.length - 1);
    }
    return node;
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
      this.onTripleTapDown,
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
  final GestureTapDownCallback? onTripleTapDown;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;
}

const Duration kTripleTapTimeout = Duration(milliseconds: 500);

class _SelectionGestureDetectorState extends State<_SelectionGestureDetector> {
  bool _isDoubleTap = false;
  Timer? _doubleTapTimer;
  int _tripleTabCount = 0;
  Timer? _tripleTabTimer;
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
    if (_tripleTabCount == 2) {
      _tripleTabCount = 0;
      _tripleTabTimer?.cancel();
      _tripleTabTimer = null;
      if (widget.onTripleTapDown != null) {
        widget.onTripleTapDown!(tapDownDetails);
      }
    } else if (_isDoubleTap) {
      _isDoubleTap = false;
      _doubleTapTimer?.cancel();
      _doubleTapTimer = null;
      if (widget.onDoubleTapDown != null) {
        widget.onDoubleTapDown!(tapDownDetails);
      }
      _tripleTabCount++;
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

      _tripleTabCount = 1;
      _tripleTabTimer?.cancel();
      _tripleTabTimer = Timer(kTripleTapTimeout, () {
        _tripleTabCount = 0;
        _tripleTabTimer = null;
      });
    }
  }

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _tripleTabTimer?.cancel();
    super.dispose();
  }
}
