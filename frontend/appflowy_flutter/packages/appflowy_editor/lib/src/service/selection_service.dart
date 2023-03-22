import 'dart:async';

import 'package:appflowy_editor/src/flutter/overlay.dart';
import 'package:appflowy_editor/src/infra/log.dart';
import 'package:appflowy_editor/src/service/context_menu/built_in_context_menu_item.dart';
import 'package:appflowy_editor/src/service/context_menu/context_menu.dart';
import 'package:flutter/material.dart' hide Overlay, OverlayEntry;

import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/node_iterator.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/core/location/position.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/extensions/node_extensions.dart';
import 'package:appflowy_editor/src/extensions/object_extensions.dart';
import 'package:appflowy_editor/src/render/selection/cursor_widget.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/render/selection/selection_widget.dart';
import 'package:appflowy_editor/src/service/selection/selection_gesture.dart';

/// [AppFlowySelectionService] is responsible for processing
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
abstract class AppFlowySelectionService {
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
  /// For example, Here is an array of selected nodes, `[n1, n2, n3]`.
  /// The result will be `[n3, n2, n1]` if the selection is forward,
  ///   and `[n1, n2, n3]` if the selection is backward.
  ///
  /// Returns empty result if there is no nodes are selected.
  List<Node> get currentSelectedNodes;

  /// Updates the selection.
  ///
  /// The editor will update selection area and toolbar area
  /// if the [selection] is not collapsed,
  /// otherwise, will update the cursor area.
  void updateSelection(Selection? selection);

  /// Clears the selection area, cursor area and the popup list area.
  void clearSelection();

  /// Clears the cursor area.
  void clearCursor();

  /// Returns the [Node]s in [Selection].
  List<Node> getNodesInSelection(Selection selection);

  /// Returns the [Node] containing to the [offset].
  ///
  /// [offset] must be under the global coordinate system.
  Node? getNodeInOffset(Offset offset);

  /// Returns the [Position] closest to the [offset].
  ///
  /// Returns null if there is no nodes are selected.
  ///
  /// [offset] must be under the global coordinate system.
  Position? getPositionInOffset(Offset offset);

  /// The current selection areas's rect in editor.
  List<Rect> get selectionRects;

  void register(SelectionInterceptor interceptor);
  void unRegister(SelectionInterceptor interceptor);
}

class SelectionInterceptor {
  bool Function(TapDownDetails details)? canTap;
}

class AppFlowySelection extends StatefulWidget {
  const AppFlowySelection({
    Key? key,
    this.cursorColor = const Color(0xFF00BCF0),
    this.selectionColor = const Color.fromARGB(53, 111, 201, 231),
    this.editable = true,
    required this.editorState,
    required this.child,
  }) : super(key: key);

  final EditorState editorState;
  final Widget child;
  final Color cursorColor;
  final Color selectionColor;
  final bool editable;

  @override
  State<AppFlowySelection> createState() => _AppFlowySelectionState();
}

class _AppFlowySelectionState extends State<AppFlowySelection>
    with WidgetsBindingObserver
    implements AppFlowySelectionService {
  final _cursorKey = GlobalKey(debugLabel: 'cursor');

  @override
  final List<Rect> selectionRects = [];
  final List<OverlayEntry> _selectionAreas = [];
  final List<OverlayEntry> _cursorAreas = [];
  final List<OverlayEntry> _contextMenuAreas = [];

  // OverlayEntry? _debugOverlay;

  /// Pan
  Offset? _panStartOffset;
  double? _panStartScrollDy;

  EditorState get editorState => widget.editorState;

  // Toolbar
  Timer? _toolbarTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    currentSelection.addListener(_onSelectionChange);
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
    currentSelection.removeListener(_onSelectionChange);
    _clearToolbar();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.editable) {
      return Container(
        child: widget.child,
      );
    } else {
      return SelectionGestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        onTapDown: _onTapDown,
        onSecondaryTapDown: _onSecondaryTapDown,
        onDoubleTapDown: _onDoubleTapDown,
        onTripleTapDown: _onTripleTapDown,
        child: widget.child,
      );
    }
  }

  @override
  ValueNotifier<Selection?> currentSelection = ValueNotifier(null);

  @override
  List<Node> currentSelectedNodes = [];

  @override
  List<Node> getNodesInSelection(Selection selection) {
    final start =
        selection.isBackward ? selection.start.path : selection.end.path;
    final end =
        selection.isBackward ? selection.end.path : selection.start.path;
    assert(start <= end);
    final startNode = editorState.document.nodeAtPath(start);
    final endNode = editorState.document.nodeAtPath(end);
    if (startNode != null && endNode != null) {
      final nodes = NodeIterator(
        document: editorState.document,
        startNode: startNode,
        endNode: endNode,
      ).toList();
      if (selection.isBackward) {
        return nodes;
      } else {
        return nodes.reversed.toList(growable: false);
      }
    }
    return [];
  }

  @override
  void updateSelection(Selection? selection) {
    if (!widget.editable) {
      return;
    }

    selectionRects.clear();
    clearSelection();
    _clearToolbar();

    if (selection != null) {
      if (selection.isCollapsed) {
        // updates cursor area.
        Log.selection.debug('update cursor area, $selection');
        _updateCursorAreas(selection.start);
      } else {
        // updates selection area.
        Log.selection.debug('update cursor area, $selection');
        _updateSelectionAreas(selection);
      }
    }

    currentSelection.value = selection;
    editorState.updateCursorSelection(selection, CursorUpdateReason.uiEvent);
  }

  @override
  void clearSelection() {
    currentSelectedNodes = [];
    currentSelection.value = null;

    clearCursor();
    // clear selection areas
    _selectionAreas
      ..forEach((overlay) => overlay.remove())
      ..clear();
    // clear cursor areas

    // hide toolbar
    // editorState.service.toolbarService?.hide();

    // clear context menu
    _clearContextMenu();
  }

  @override
  void clearCursor() {
    // clear cursor areas
    _cursorAreas
      ..forEach((overlay) => overlay.remove())
      ..clear();
  }

  void _clearContextMenu() {
    _contextMenuAreas
      ..forEach((overlay) => overlay.remove())
      ..clear();
  }

  @override
  Node? getNodeInOffset(Offset offset) {
    final sortedNodes =
        editorState.document.root.children.toList(growable: false);
    return _getNodeInOffset(
      sortedNodes,
      offset,
      0,
      sortedNodes.length - 1,
    );
  }

  @override
  Position? getPositionInOffset(Offset offset) {
    final node = getNodeInOffset(offset);
    final selectable = node?.selectable;
    if (selectable == null) {
      clearSelection();
      return null;
    }
    return selectable.getPositionInOffset(offset);
  }

  void _onTapDown(TapDownDetails details) {
    final canTap =
        _interceptors.every((element) => element.canTap?.call(details) ?? true);
    if (!canTap) return;

    // clear old state.
    _panStartOffset = null;

    final position = getPositionInOffset(details.globalPosition);
    if (position == null) {
      return;
    }
    final selection = Selection.collapsed(position);
    updateSelection(selection);

    _enableInteraction();

    _showDebugLayerIfNeeded(offset: details.globalPosition);
  }

  void _onDoubleTapDown(TapDownDetails details) {
    final offset = details.globalPosition;
    final node = getNodeInOffset(offset);
    final selection = node?.selectable?.getWordBoundaryInOffset(offset);
    if (selection == null) {
      clearSelection();
      return;
    }
    updateSelection(selection);

    _enableInteraction();
  }

  void _onTripleTapDown(TapDownDetails details) {
    final offset = details.globalPosition;
    final node = getNodeInOffset(offset);
    final selectable = node?.selectable;
    if (selectable == null) {
      clearSelection();
      return;
    }
    Selection selection = Selection(
      start: selectable.start(),
      end: selectable.end(),
    );
    updateSelection(selection);

    _enableInteraction();
  }

  void _onSecondaryTapDown(TapDownDetails details) {
    // if selection is null, or
    // selection.isCollapsedand and the selected node is TextNode.
    // try to select the word.
    final selection = currentSelection.value;
    if (selection == null ||
        (selection.isCollapsed == true &&
            currentSelectedNodes.first is TextNode)) {
      _onDoubleTapDown(details);
    }

    _showContextMenu(details);
  }

  void _onPanStart(DragStartDetails details) {
    clearSelection();
    _clearToolbar();

    _panStartOffset = details.globalPosition.translate(-3.0, 0);
    _panStartScrollDy = editorState.service.scrollService?.dy;

    _enableInteraction();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_panStartOffset == null || _panStartScrollDy == null) {
      return;
    }

    _enableInteraction();

    final panEndOffset = details.globalPosition;
    final dy = editorState.service.scrollService?.dy;
    final panStartOffset = dy == null
        ? _panStartOffset!
        : _panStartOffset!.translate(0, _panStartScrollDy! - dy);

    final first = getNodeInOffset(panStartOffset)?.selectable;
    final last = getNodeInOffset(panEndOffset)?.selectable;

    // compute the selection in range.
    if (first != null && last != null) {
      Log.selection.debug('first = $first, last = $last');
      final start =
          first.getSelectionInRange(panStartOffset, panEndOffset).start;
      final end = last.getSelectionInRange(panStartOffset, panEndOffset).end;
      final selection = Selection(start: start, end: end);
      updateSelection(selection);
    }

    _showDebugLayerIfNeeded(offset: panEndOffset);
  }

  void _onPanEnd(DragEndDetails details) {
    // do nothing
  }

  void _updateSelectionAreas(Selection selection) {
    final nodes = getNodesInSelection(selection);

    currentSelectedNodes = nodes;

    // TODO: need to be refactored.
    Offset? toolbarOffset;
    Alignment? alignment;
    LayerLink? layerLink;
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorSize = editorState.renderBox?.size ?? Size.zero;

    final backwardNodes =
        selection.isBackward ? nodes : nodes.reversed.toList(growable: false);
    final normalizedSelection = selection.normalized;
    assert(normalizedSelection.isBackward);

    Log.selection.debug('update selection areas, $normalizedSelection');

    for (var i = 0; i < backwardNodes.length; i++) {
      final node = backwardNodes[i];
      final selectable = node.selectable;
      if (selectable == null) {
        continue;
      }

      var newSelection = normalizedSelection.copyWith();

      /// In the case of multiple selections,
      ///  we need to return a new selection for each selected node individually.
      ///
      /// < > means selected.
      /// text: abcd<ef
      /// text: ghijkl
      /// text: mn>opqr
      ///
      if (!normalizedSelection.isSingle) {
        if (i == 0) {
          newSelection = newSelection.copyWith(end: selectable.end());
        } else if (i == nodes.length - 1) {
          newSelection = newSelection.copyWith(start: selectable.start());
        } else {
          newSelection = Selection(
            start: selectable.start(),
            end: selectable.end(),
          );
        }
      }

      const baseToolbarOffset = Offset(0, 35.0);
      final rects = selectable.getRectsInSelection(newSelection);
      for (final rect in rects) {
        final selectionRect = _transformRectToGlobal(selectable, rect);
        selectionRects.add(selectionRect);

        // TODO: Need to compute more precise location.
        if ((selectionRect.topLeft.dy - editorOffset.dy) <=
            baseToolbarOffset.dy) {
          if (selectionRect.topLeft.dx <=
              editorSize.width / 3.0 + editorOffset.dx) {
            toolbarOffset ??= rect.bottomLeft;
            alignment ??= Alignment.topLeft;
          } else if (selectionRect.topRight.dx >=
              editorSize.width * 2.0 / 3.0 + editorOffset.dx) {
            toolbarOffset ??= rect.bottomRight;
            alignment ??= Alignment.topRight;
          } else {
            toolbarOffset ??= rect.bottomCenter;
            alignment ??= Alignment.topCenter;
          }
        } else {
          if (selectionRect.topLeft.dx <=
              editorSize.width / 3.0 + editorOffset.dx) {
            toolbarOffset ??= rect.topLeft - baseToolbarOffset;
            alignment ??= Alignment.topLeft;
          } else if (selectionRect.topRight.dx >=
              editorSize.width * 2.0 / 3.0 + editorOffset.dx) {
            toolbarOffset ??= rect.topRight - baseToolbarOffset;
            alignment ??= Alignment.topRight;
          } else {
            toolbarOffset ??= rect.topCenter - baseToolbarOffset;
            alignment ??= Alignment.topCenter;
          }
        }

        layerLink ??= node.layerLink;

        final overlay = OverlayEntry(
          builder: (context) => SelectionWidget(
            color: widget.selectionColor,
            layerLink: node.layerLink,
            rect: rect,
          ),
        );
        _selectionAreas.add(overlay);
      }
    }

    Overlay.of(context)?.insertAll(_selectionAreas);

    // show toolbar
    _showToolbarWithDelay(toolbarOffset, layerLink, alignment!);
  }

  void _updateCursorAreas(Position position) {
    final node = editorState.document.root.childAtPath(position.path);

    if (node == null) {
      assert(false);
      return;
    }

    currentSelectedNodes = [node];

    _showCursor(node, position);
    _clearToolbar();
  }

  void _showCursor(Node node, Position position) {
    final selectable = node.selectable;
    final cursorRect = selectable?.getCursorRectInPosition(position);
    if (selectable != null && cursorRect != null) {
      final cursorArea = OverlayEntry(
        builder: (context) => CursorWidget(
          key: _cursorKey,
          rect: cursorRect,
          color: widget.cursorColor,
          layerLink: node.layerLink,
          shouldBlink: selectable.shouldCursorBlink,
          cursorStyle: selectable.cursorStyle,
        ),
      );

      _cursorAreas.add(cursorArea);
      selectionRects.add(_transformRectToGlobal(selectable, cursorRect));
      Overlay.of(context)?.insertAll(_cursorAreas);

      _forceShowCursor();
    }
  }

  void _forceShowCursor() {
    _cursorKey.currentState?.unwrapOrNull<CursorWidgetState>()?.show();
  }

  void _showContextMenu(TapDownDetails details) {
    _clearContextMenu();

    // For now, only support the text node.
    if (!currentSelectedNodes.every((element) => element is TextNode)) {
      return;
    }

    final baseOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final offset = details.globalPosition + const Offset(10, 10) - baseOffset;
    final contextMenu = OverlayEntry(
      builder: (context) => ContextMenu(
        position: offset,
        editorState: editorState,
        items: builtInContextMenuItems,
        onPressed: () => _clearContextMenu(),
      ),
    );

    _contextMenuAreas.add(contextMenu);
    Overlay.of(context)?.insert(contextMenu);
  }

  void _scrollUpOrDownIfNeeded() {
    final dy = editorState.service.scrollService?.dy;
    final selectNodes = currentSelectedNodes;
    final selection = currentSelection.value;
    if (dy == null || selection == null || selectNodes.isEmpty) {
      return;
    }

    final rect = selectNodes.last.rect;

    final size = MediaQuery.of(context).size.height;
    final topLimit = size * 0.3;
    final bottomLimit = size * 0.8;

    // TODO: It is necessary to calculate the relative speed
    //   according to the gap and move forward more gently.
    if (rect.top >= bottomLimit) {
      if (selection.isSingle) {
        editorState.service.scrollService?.scrollTo(dy + size * 0.2);
      } else if (selection.isBackward) {
        editorState.service.scrollService?.scrollTo(dy + 10.0);
      }
    } else if (rect.bottom <= topLimit) {
      if (selection.isForward) {
        editorState.service.scrollService?.scrollTo(dy - 10.0);
      }
    }
  }

  Node? _getNodeInOffset(
      List<Node> sortedNodes, Offset offset, int start, int end) {
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
      return _getNodeInOffset(
        children,
        offset,
        0,
        children.length - 1,
      );
    }
    return node;
  }

  void _enableInteraction() {
    editorState.service.keyboardService?.enable();
    editorState.service.scrollService?.enable();
  }

  Rect _transformRectToGlobal(SelectableMixin selectable, Rect r) {
    final Offset topLeft = selectable.localToGlobal(Offset(r.left, r.top));
    return Rect.fromLTWH(topLeft.dx, topLeft.dy, r.width, r.height);
  }

  void _onSelectionChange() {
    _scrollUpOrDownIfNeeded();
  }

  void _showToolbarWithDelay(
    Offset? toolbarOffset,
    LayerLink? layerLink,
    Alignment alignment, {
    Duration delay = const Duration(milliseconds: 400),
  }) {
    if (toolbarOffset == null && layerLink == null) {
      _clearToolbar();
      return;
    }
    if (_toolbarTimer?.isActive ?? false) {
      _toolbarTimer?.cancel();
    }
    _toolbarTimer = Timer(
      delay,
      () {
        if (toolbarOffset != null && layerLink != null) {
          editorState.service.toolbarService?.showInOffset(
            toolbarOffset,
            alignment,
            layerLink,
          );
        }
      },
    );
  }

  void _clearToolbar() {
    editorState.service.toolbarService?.hide();
    if (_toolbarTimer?.isActive ?? false) {
      _toolbarTimer?.cancel();
    }
  }

  void _showDebugLayerIfNeeded({Offset? offset}) {
    // remove false to show debug overlay.
    // if (kDebugMode && false) {
    //   _debugOverlay?.remove();
    //   if (offset != null) {
    //     _debugOverlay = OverlayEntry(
    //       builder: (context) => Positioned.fromRect(
    //         rect: Rect.fromPoints(offset, offset.translate(20, 20)),
    //         child: Container(
    //           color: Colors.red.withOpacity(0.2),
    //         ),
    //       ),
    //     );
    //     Overlay.of(context)?.insert(_debugOverlay!);
    //   } else if (_panStartOffset != null) {
    //     _debugOverlay = OverlayEntry(
    //       builder: (context) => Positioned.fromRect(
    //         rect: Rect.fromPoints(
    //             _panStartOffset?.translate(
    //                   0,
    //                   -(editorState.service.scrollService!.dy -
    //                       _panStartScrollDy!),
    //                 ) ??
    //                 Offset.zero,
    //             offset ?? Offset.zero),
    //         child: Container(
    //           color: Colors.red.withOpacity(0.2),
    //         ),
    //       ),
    //     );
    //     Overlay.of(context)?.insert(_debugOverlay!);
    //   } else {
    //     _debugOverlay = null;
    //   }
    // }
  }

  final List<SelectionInterceptor> _interceptors = [];
  @override
  void register(SelectionInterceptor interceptor) {
    _interceptors.add(interceptor);
  }

  @override
  void unRegister(SelectionInterceptor interceptor) {
    _interceptors.removeWhere((element) => element == interceptor);
  }
}
