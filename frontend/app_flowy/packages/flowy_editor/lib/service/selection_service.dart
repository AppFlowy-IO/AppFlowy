import 'package:flowy_editor/document/path.dart';
import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/render/selection/cursor_widget.dart';
import 'package:flowy_editor/render/selection/flowy_selection_widget.dart';
import 'package:flowy_editor/extensions/object_extensions.dart';
import 'package:flowy_editor/extensions/node_extensions.dart';
import 'package:flowy_editor/service/shortcut_service.dart';
import 'package:flowy_editor/editor_state.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Process selection and cursor
mixin FlowySelectionService<T extends StatefulWidget> on State<T> {
  /// Returns the currently selected [Node]s.
  ///
  /// The order of the return is determined according to the selected order.
  ValueNotifier<List<Node>> get currentSelectedNodes;
  Selection? get currentSelection;

  /// ------------------ Selection ------------------------

  ///
  void updateSelection(Selection selection);

  ///
  void clearSelection();

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

  /// Return the [Node]s in multiple selection. Emtpy list would be returned
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

  /// [Pan] and [Tap] must be mutually exclusive.
  /// Pan
  Offset? panStartOffset;
  Offset? panEndOffset;

  /// Tap
  Offset? tapOffset;

  EditorState get editorState => widget.editorState;

  @override
  Selection? currentSelection;

  @override
  ValueNotifier<List<Node>> currentSelectedNodes = ValueNotifier([]);

  @override
  List<Node> getNodesInSelection(Selection selection) =>
      _selectedNodesInSelection(editorState.document.root, selection);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // Need to refresh the selection when the metrics changed.
    if (currentSelection != null) {
      updateSelection(currentSelection!);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

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
              ..onStart = _onPanStart
              ..onUpdate = _onPanUpdate
              ..onEnd = _onPanEnd;
          },
        ),
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(),
          (recognizer) {
            recognizer.onTapDown = _onTapDown;
          },
        )
      },
      child: widget.child,
    );
  }

  @override
  void updateSelection(Selection selection) {
    _clearSelection();

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
    _clearSelection();
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
      result.addAll(computeNodesInRange(child, start, end));
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

  void _onTapDown(TapDownDetails details) {
    // clear old state.
    panStartOffset = null;
    panEndOffset = null;

    tapOffset = details.globalPosition;

    final nodes = getNodesInRange(tapOffset!);
    if (nodes.isNotEmpty) {
      assert(nodes.length == 1);
      final selectable = nodes.first.selectable;
      if (selectable != null) {
        final position = selectable.getPositionInOffset(tapOffset!);
        final selection = Selection.collapsed(position);
        updateSelection(selection);
      }
    }
  }

  void _onPanStart(DragStartDetails details) {
    // clear old state.
    panEndOffset = null;
    tapOffset = null;
    clearSelection();

    panStartOffset = details.globalPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    panEndOffset = details.globalPosition;

    final nodes = getNodesInRange(panStartOffset!, panEndOffset!);
    if (nodes.isEmpty) {
      return;
    }
    final first = nodes.first.selectable;
    final last = nodes.last.selectable;

    // compute the selection in range.
    if (first != null && last != null) {
      bool isDownward = panStartOffset!.dy <= panEndOffset!.dy;
      final start =
          first.getSelectionInRange(panStartOffset!, panEndOffset!).start;
      final end = last.getSelectionInRange(panStartOffset!, panEndOffset!).end;
      final selection = Selection(
          start: isDownward ? start : end, end: isDownward ? end : start);
      debugPrint('[_onPanUpdate] $selection');
      updateSelection(selection);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    // do nothing
  }

  void _clearSelection() {
    currentSelection = null;
    currentSelectedNodes.value = [];

    // clear selection
    _selectionOverlays
      ..forEach((overlay) => overlay.remove())
      ..clear();
    // clear cursors
    _cursorOverlays
      ..forEach((overlay) => overlay.remove())
      ..clear();
    // clear floating shortcuts
    editorState.service.floatingShortcutServiceKey.currentState
        ?.unwrapOrNull<FlowyFloatingShortcutService>()
        ?.hide();
  }

  void _updateSelection(Selection selection) {
    final nodes =
        _selectedNodesInSelection(editorState.document.root, selection);

    currentSelection = selection;
    currentSelectedNodes.value = nodes;

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
        final overlay = OverlayEntry(
          builder: ((context) => SelectionWidget(
                color: widget.selectionColor,
                layerLink: node.layerLink,
                rect: rect,
              )),
        );
        _selectionOverlays.add(overlay);
      }
      index += 1;
    }
    Overlay.of(context)?.insertAll(_selectionOverlays);
  }

  void _updateCursor(Position position) {
    final node = editorState.document.root.childAtPath(position.path);

    assert(node != null);
    if (node == null) {
      return;
    }

    currentSelection = Selection.collapsed(position);
    currentSelectedNodes.value = [node];

    final selectable = node.selectable;
    final rect = selectable?.getCursorRectInPosition(position);
    if (rect != null) {
      final cursor = OverlayEntry(
        builder: ((context) => CursorWidget(
              key: _cursorKey,
              rect: rect,
              color: widget.cursorColor,
              layerLink: node.layerLink,
            )),
      );
      _cursorOverlays.add(cursor);
      Overlay.of(context)?.insertAll(_cursorOverlays);
    }
  }

  List<Node> _selectedNodesInSelection(Node node, Selection selection) {
    List<Node> result = [];
    if (node.parent != null) {
      if (node.inSelection(selection)) {
        result.add(node);
      }
    }
    for (final child in node.children) {
      result.addAll(_selectedNodesInSelection(child, selection));
    }
    return result;
  }
}
