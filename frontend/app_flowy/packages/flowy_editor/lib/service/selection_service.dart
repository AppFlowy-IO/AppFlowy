import 'package:flowy_editor/document/path.dart';
import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
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
  ///
  void updateSelection(Selection selection);

  /// Returns selected [Node]s. Empty list would be returned
  ///   if no nodes are being selected.
  ///
  ///
  /// [start] and [end] are the offsets under the global coordinate system.
  ///
  /// If end is not null, it means multiple selection,
  ///   otherwise single selection.
  List<Node> getNodesInRange(Offset start, [Offset? end]);

  ///
  List<Node> getNodesInSelection(Selection selection);

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
  List<Node> getNodesInSelection(Selection selection) =>
      _selectedNodesInSelection(editorState.document.root, selection);

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
  void updateSelection(Selection selection) {
    _clearAllOverlayEntries();

    // cursor
    if (selection.isCollapsed()) {
      _updateCursor(selection.start);
    } else {
      _updateSelection(selection);
    }
  }

  @override
  List<Node> getNodesInRange(Offset start, [Offset? end]) {
    if (end != null) {
      return computeNodesInRange(editorState.document.root, start, end);
    } else {
      final reuslt = computeNodeInOffset(editorState.document.root, start);
      if (reuslt != null) {
        return [reuslt];
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
    List<Node> result = [];
    if (node.parent != null && node.key != null) {
      if (isNodeInSelection(node, start, end)) {
        result.add(node);
      }
    }
    for (final child in node.children) {
      result.addAll(computeNodesInRange(child, start, end));
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
    debugPrint('on pan start');

    panStartOffset = details.globalPosition;
    panEndOffset = null;
    tapOffset = null;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    // debugPrint('on pan update');

    panEndOffset = details.globalPosition;
    tapOffset = null;

    final nodes = getNodesInRange(panStartOffset!, panEndOffset!);
    final first = nodes.first.selectable;
    final last = nodes.last.selectable;
    if (first != null && last != null) {
      final selection = Selection(
        start: first.getSelectionInRange(panStartOffset!, panEndOffset!).start,
        end: last.getSelectionInRange(panStartOffset!, panEndOffset!).end,
      );
      updateSelection(selection);
    }
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

  void _updateSelection(Selection selection) {
    final nodes =
        _selectedNodesInSelection(editorState.document.root, selection);

    var index = 0;
    for (final node in nodes) {
      final selectable = node.selectable;
      if (selectable == null) {
        continue;
      }

      Selection newSelection;
      if (node is TextNode) {
        if (pathEquals(selection.start.path, selection.end.path)) {
          newSelection = selection.copyWith();
        } else {
          if (index == 0) {
            newSelection = selection.copyWith(
              /// FIXME: make it better.
              end: selection.start.copyWith(offset: node.toRawString().length),
            );
          } else if (index == nodes.length - 1) {
            newSelection = selection.copyWith(
              /// FIXME: make it better.
              start: selection.end.copyWith(offset: 0),
            );
          } else {
            final position = Position(path: node.path);
            newSelection = Selection(
              start: position.copyWith(offset: 0),
              end: position.copyWith(offset: node.toRawString().length),
            );
          }
        }
      } else {
        newSelection = Selection.collapsed(
          Position(path: node.path),
        );
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
    final node = _selectedNodeInPostion(editorState.document.root, position);

    assert(node != null);
    if (node == null) {
      return;
    }

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
      if (_isNodeInSelection(node, selection)) {
        result.add(node);
      }
    }
    for (final child in node.children) {
      result.addAll(_selectedNodesInSelection(child, selection));
    }
    return result;
  }

  Node? _selectedNodeInPostion(Node node, Position position) =>
      node.childAtPath(position.path);

  bool _isNodeInSelection(Node node, Selection selection) {
    return pathGreaterOrEquals(node.path, selection.start.path) &&
        pathLessOrEquals(node.path, selection.end.path);
  }
}
