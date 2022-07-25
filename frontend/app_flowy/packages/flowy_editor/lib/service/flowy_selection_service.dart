import 'package:flowy_editor/render/selection/flowy_cursor_widget.dart';
import 'package:flowy_editor/render/selection/flowy_selection_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../editor_state.dart';
import '../document/node.dart';
import '../render/selection/selectable.dart';

/// Process selection and cursor
mixin _FlowySelectionService<T extends StatefulWidget> on State<T> {
  /// [Pan] and [Tap] must be mutually exclusive.
  /// Pan
  Offset? panStartOffset;
  Offset? panEndOffset;

  /// Tap
  Offset? tapOffset;

  void updateSelection(Offset start, Offset end);

  void updateCursor(Offset offset);

  /// Returns selected node(s)
  /// Returns empty list if no nodes are being selected.
  List<Node> get selectedNodes;

  /// Compute selected node triggered by [Tap]
  Node? computeSelectedNodeByTap(
    Node node,
    Offset offset,
  );

  /// Compute selected nodes triggered by [Pan]
  List<Node> computeSelectedNodesByPan(
    Node node,
    Offset start,
    Offset end,
  );

  /// Pan
  bool isNodeInSelection(
    Node node,
    Offset start,
    Offset end,
  );

  /// Tap
  bool isNodeInOffset(
    Node node,
    Offset offset,
  );
}

class FlowySelectionService extends StatefulWidget {
  const FlowySelectionService({
    Key? key,
    required this.editorState,
    required this.child,
  }) : super(key: key);

  final EditorState editorState;
  final Widget child;

  @override
  State<FlowySelectionService> createState() => _FlowySelectionServiceState();
}

class _FlowySelectionServiceState extends State<FlowySelectionService>
    with _FlowySelectionService {
  final _cursorKey = GlobalKey(debugLabel: 'cursor');

  final List<OverlayEntry> _selectionOverlays = [];
  final List<OverlayEntry> _cursorOverlays = [];

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

    final nodes = selectedNodes;
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
          builder: ((context) => FlowySelectionWidget(
                color: Colors.yellow.withAlpha(100),
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
  void updateCursor(Offset offset) {
    _clearAllOverlayEntries();

    final nodes = selectedNodes;
    editorState.selectedNodes = nodes;
    if (nodes.isEmpty) {
      return;
    }

    final selectedNode = nodes.first;
    if (selectedNode.key?.currentState is! Selectable) {
      return;
    }
    final selectable = selectedNode.key?.currentState as Selectable;
    final rect = selectable.getCursorRect(offset);
    final cursor = OverlayEntry(
      builder: ((context) => FlowyCursorWidget(
            key: _cursorKey,
            rect: rect,
            color: Colors.red,
            layerLink: selectedNode.layerLink,
          )),
    );
    _cursorOverlays.add(cursor);
    Overlay.of(context)?.insertAll(_cursorOverlays);
  }

  @override
  List<Node> get selectedNodes {
    if (panStartOffset != null && panEndOffset != null) {
      return computeSelectedNodesByPan(
          editorState.document.root, panStartOffset!, panEndOffset!);
    } else if (tapOffset != null) {
      final reuslt =
          computeSelectedNodeByTap(editorState.document.root, tapOffset!);
      if (reuslt != null) {
        return [reuslt];
      }
    }
    return [];
  }

  @override
  Node? computeSelectedNodeByTap(Node node, Offset offset) {
    assert(this.tapOffset != null);
    final tapOffset = this.tapOffset;
    if (tapOffset != null) {}

    for (final child in node.children) {
      final result = computeSelectedNodeByTap(child, offset);
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
  List<Node> computeSelectedNodesByPan(Node node, Offset start, Offset end) {
    List<Node> result = [];
    if (node.parent != null && node.key != null) {
      if (isNodeInSelection(node, start, end)) {
        result.add(node);
      }
    }
    for (final child in node.children) {
      result.addAll(computeSelectedNodesByPan(child, start, end));
    }
    // TODO: sort the result
    return result;
  }

  @override
  bool isNodeInOffset(Node node, Offset offset) {
    assert(node.key != null);
    final renderBox =
        node.key?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final boxOffset = renderBox.localToGlobal(Offset.zero);
      final boxRect = boxOffset & renderBox.size;
      return boxRect.contains(offset);
    }
    return false;
  }

  @override
  bool isNodeInSelection(Node node, Offset start, Offset end) {
    assert(node.key != null);
    final renderBox =
        node.key?.currentContext?.findRenderObject() as RenderBox?;
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
}
