import 'package:flowy_editor/document/node.dart';
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

  Offset? panStartOffset;
  Offset? panEndOffset;

  Selection? cursorSelection;

  EditorState({
    required this.document,
    required this.renderPlugins,
  });

  /// TODO: move to a better place.
  Widget build(BuildContext context) {
    return renderPlugins.buildWidget(
      context: NodeWidgetContext(
        buildContext: context,
        node: document.root,
        editorState: this,
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

  void updateSelection() {
    selectionOverlays
      ..forEach((element) => element.remove())
      ..clear();

    final selectedNodes = _selectedNodes;
    if (selectedNodes.isEmpty) {
      return;
    }

    assert(panStartOffset != null && panEndOffset != null);

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

  List<Node> get _selectedNodes {
    if (panStartOffset == null || panEndOffset == null) {
      return [];
    }
    return _calculateSelectedNodes(
        document.root, panStartOffset!, panEndOffset!);
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
