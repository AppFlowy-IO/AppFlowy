import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flowy_editor/src/document/node.dart';
import 'package:flowy_editor/src/document/position.dart';
import 'package:flowy_editor/src/document/selection.dart';

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
