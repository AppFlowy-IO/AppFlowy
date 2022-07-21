import 'dart:collection';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/keyboard.dart';
import 'package:flowy_editor/operation/operation.dart';
import 'package:flowy_editor/render/selectable.dart';
import 'package:flutter/material.dart';

import './document/state_tree.dart';
import './document/selection.dart';
import './operation/operation.dart';
import './operation/transaction.dart';
import './render/render_plugins.dart';

class EditorState {
  final StateTree document;
  final RenderPlugins renderPlugins;

  Offset? tapOffset;
  Offset? panStartOffset;
  Offset? panEndOffset;

  Selection? cursorSelection;

  EditorState({
    required this.document,
    required this.renderPlugins,
  });

  /// TODO: move to a better place.
  Widget build(BuildContext context) {
    return Keyboard(
      editorState: this,
      child: renderPlugins.buildWidget(
        context: NodeWidgetContext(
          buildContext: context,
          node: document.root,
          editorState: this,
        ),
      ),
    );
  }

  void apply(Transaction transaction) {
    for (final op in transaction.operations) {
      _applyOperation(op);
    }
    cursorSelection = transaction.afterSelection;
  }

  void _applyOperation(Operation op) {
    if (op is InsertOperation) {
      document.insert(op.path, op.value);
    } else if (op is UpdateOperation) {
      document.update(op.path, op.attributes);
    } else if (op is DeleteOperation) {
      document.delete(op.path);
    } else if (op is TextEditOperation) {
      document.textEdit(op.path, op.delta);
    }
  }

  List<OverlayEntry> selectionOverlays = [];

  void updateCursor() {
    selectionOverlays
      ..forEach((element) => element.remove())
      ..clear();

    if (tapOffset == null) {
      return;
    }

    // TODO: upward and backward
    final selectedNode = _calculateSelectedNode(document.root, tapOffset!);
    if (selectedNode.isEmpty) {
      return;
    }
    final key = selectedNode.first.key;
    if (key != null && key.currentState is Selectable) {
      final selectable = key.currentState as Selectable;
      final rect = selectable.getCursorRect(tapOffset!);
      final overlay = OverlayEntry(builder: ((context) {
        return Positioned.fromRect(
          rect: rect,
          child: Container(
            color: Colors.red,
          ),
        );
      }));
      selectionOverlays.add(overlay);
      Overlay.of(selectable.context)?.insert(overlay);
    }
  }

  void updateSelection() {
    selectionOverlays
      ..forEach((element) => element.remove())
      ..clear();

    final selectedNodes = this.selectedNodes;
    if (selectedNodes.isEmpty ||
        panStartOffset == null ||
        panEndOffset == null) {
      return;
    }

    for (final node in selectedNodes) {
      final key = node.key;
      if (key != null && key.currentState is Selectable) {
        final selectable = key.currentState as Selectable;
        final overlayRects =
            selectable.getOverlayRectsInRange(panStartOffset!, panEndOffset!);
        for (final rect in overlayRects) {
          // TODO: refactor overlay implement.
          final overlay = OverlayEntry(builder: ((context) {
            return Positioned.fromRect(
              rect: rect,
              child: Container(
                color: Colors.yellow.withAlpha(100),
              ),
            );
          }));
          selectionOverlays.add(overlay);
          Overlay.of(selectable.context)?.insert(overlay);
        }
      }
    }
  }

  List<Node> get selectedNodes {
    if (panStartOffset != null && panEndOffset != null) {
      return _calculateSelectedNodes(
          document.root, panStartOffset!, panEndOffset!);
    }
    if (tapOffset != null) {
      return _calculateSelectedNode(document.root, tapOffset!);
    }
    return [];
  }

  List<Node> _calculateSelectedNode(Node node, Offset offset) {
    List<Node> result = [];

    /// Skip the node without parent because it is the topmost node.
    /// Skip the node without key because it cannot get the [RenderObject].
    if (node.parent != null && node.key != null) {
      if (_isNodeInOffset(node, offset)) {
        result.add(node);
      }
    }

    ///
    for (final child in node.children) {
      result.addAll(_calculateSelectedNode(child, offset));
    }

    return result;
  }

  bool _isNodeInOffset(Node node, Offset offset) {
    assert(node.key != null);
    final renderBox =
        node.key?.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return false;
    }
    final boxOffset = renderBox.localToGlobal(Offset.zero);
    final boxRect = boxOffset & renderBox.size;
    return boxRect.contains(offset);
  }

  List<Node> _calculateSelectedNodes(Node node, Offset start, Offset end) {
    List<Node> result = [];

    /// Skip the node without parent because it is the topmost node.
    /// Skip the node without key because it cannot get the [RenderObject].
    if (node.parent != null && node.key != null) {
      if (_isNodeInRange(node, start, end)) {
        result.add(node);
      }
    }

    ///
    for (final child in node.children) {
      result.addAll(_calculateSelectedNodes(child, start, end));
    }

    return result;
  }

  bool _isNodeInRange(Node node, Offset start, Offset end) {
    assert(node.key != null);
    final renderBox =
        node.key?.currentContext?.findRenderObject() as RenderBox?;

    /// Return false directly if the [RenderBox] cannot found.
    if (renderBox == null) {
      return false;
    }

    final rect = Rect.fromPoints(start, end);
    final boxOffset = renderBox.localToGlobal(Offset.zero);
    return rect.overlaps(boxOffset & renderBox.size);
  }
}
