import 'package:flowy_editor/render/selection/cursor_widget.dart';
import 'package:flowy_editor/render/selection/flowy_selection_widget.dart';
import 'package:flowy_editor/extensions/object_extensions.dart';
import 'package:flowy_editor/extensions/node_extensions.dart';
import 'package:flowy_editor/service/shortcut_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../editor_state.dart';
import '../document/node.dart';
import '../render/selection/selectable.dart';

/// Process selection and cursor
mixin FlowySelectionService<T extends StatefulWidget> on State<T> {
  /// [start] and [end] are the offsets under the global coordinate system.
  void updateSelection(Offset start, Offset end);

  /// [start] is the offset under the global coordinate system.
  void updateCursor(Offset start);

  /// Returns selected [Node]s. Empty list would be returned
  ///   if no nodes are being selected.
  ///
  ///
  /// [start] and [end] are the offsets under the global coordinate system.
  ///
  /// If end is not null, it means multiple selection,
  ///   otherwise single selection.
  List<Node> getSelectedNodes(Offset start, [Offset? end]);

  /// Return the [Node] or [Null] in single selection.
  ///
  /// [start] is the offset under the global coordinate system.
  Node? computeSelectedNodeInOffset(Node node, Offset offset);

  /// Return the [Node]s in multiple selection. Emtpy list would be returned
  ///   if no nodes are in range.
  ///
  /// [start] is the offset under the global coordinate system.
  List<Node> computeSelectedNodesInRange(
    Node node,
    Offset start,
    Offset end,
  );

  /// Return [bool] to identify the [Node] is in Range or not.
  ///
  /// [start] and [end] are the offsets under the global coordinate system.
  bool isNodeInSelection(
    Node node,
    Offset start,
    Offset end,
  );

  /// Return [bool] to identify the [Node] contains [Offset] or not.
  ///
  /// [start] is the offset under the global coordinate system.
  bool isNodeInOffset(Node node, Offset offset);
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
    with FlowySelectionService {
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
          (recongizer) {
            recongizer.onTapDown = _onTapDown;
          },
        )
      },
      child: widget.child,
    );
  }

  @override
  void updateSelection(Offset start, Offset end) {
    _clearAllOverlayEntries();

    final nodes = getSelectedNodes(start, end);
    editorState.selectedNodes = nodes;
    if (nodes.isEmpty) {
      return;
    }

    for (final node in nodes) {
      if (node.key?.currentState is! Selectable) {
        continue;
      }
      final selectable = node.key?.currentState as Selectable;
      final selectionRects = selectable.getSelectionRectsInRange(start, end);
      for (final rect in selectionRects) {
        final overlay = OverlayEntry(
          builder: ((context) => SelectionWidget(
                color: widget.selectionColor,
                layerLink: node.layerLink,
                rect: rect,
              )),
        );
        _selectionOverlays.add(overlay);
      }
    }
    Overlay.of(context)?.insertAll(_selectionOverlays);
  }

  @override
  void updateCursor(Offset start) {
    _clearAllOverlayEntries();

    final nodes = getSelectedNodes(start);
    editorState.selectedNodes = nodes;
    if (nodes.isEmpty) {
      return;
    }

    final selectedNode = nodes.first;
    if (selectedNode.key?.currentState is! Selectable) {
      return;
    }
    final selectable = selectedNode.key?.currentState as Selectable;
    final rect = selectable.getCursorRect(start);
    final cursor = OverlayEntry(
      builder: ((context) => CursorWidget(
            key: _cursorKey,
            rect: rect,
            color: widget.cursorColor,
            layerLink: selectedNode.layerLink,
          )),
    );
    _cursorOverlays.add(cursor);
    Overlay.of(context)?.insertAll(_cursorOverlays);
  }

  @override
  List<Node> getSelectedNodes(Offset start, [Offset? end]) {
    if (end != null) {
      return computeSelectedNodesInRange(editorState.document.root, start, end);
    } else {
      final reuslt =
          computeSelectedNodeInOffset(editorState.document.root, start);
      if (reuslt != null) {
        return [reuslt];
      }
    }
    return [];
  }

  @override
  Node? computeSelectedNodeInOffset(Node node, Offset offset) {
    for (final child in node.children) {
      final result = computeSelectedNodeInOffset(child, offset);
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
  List<Node> computeSelectedNodesInRange(Node node, Offset start, Offset end) {
    List<Node> result = [];
    if (node.parent != null && node.key != null) {
      if (isNodeInSelection(node, start, end)) {
        result.add(node);
      }
    }
    for (final child in node.children) {
      result.addAll(computeSelectedNodesInRange(child, start, end));
    }
    // TODO: sort the result
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
  bool isNodeInSelection(Node node, Offset start, Offset end) {
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
    debugPrint('on tap down');

    // TODO: use setter to make them exclusive??
    tapOffset = details.globalPosition;
    panStartOffset = null;
    panEndOffset = null;

    updateCursor(tapOffset!);
  }

  void _onPanStart(DragStartDetails details) {
    debugPrint('on pan start');

    panStartOffset = details.globalPosition;
    panEndOffset = null;
    tapOffset = null;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // debugPrint('on pan update');

    panEndOffset = details.globalPosition;
    tapOffset = null;

    updateSelection(panStartOffset!, panEndOffset!);
  }

  void _onPanEnd(DragEndDetails details) {
    // do nothing
  }

  void _clearAllOverlayEntries() {
    _clearSelection();
    _clearCursor();
    _clearFloatingShorts();
  }

  void _clearSelection() {
    _selectionOverlays
      ..forEach((overlay) => overlay.remove())
      ..clear();
  }

  void _clearCursor() {
    _cursorOverlays
      ..forEach((overlay) => overlay.remove())
      ..clear();
  }

  void _clearFloatingShorts() {
    final shortcutService = editorState
        .service.floatingShortcutServiceKey.currentState
        ?.unwrapOrNull<FlowyFloatingShortcutService>();
    shortcutService?.hide();
  }
}
