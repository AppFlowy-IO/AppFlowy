import 'package:appflowy_editor/src/core/document/node.dart';
import 'package:appflowy_editor/src/core/document/path.dart';
import 'package:appflowy_editor/src/core/location/selection.dart';
import 'package:appflowy_editor/src/editor_state.dart';
import 'package:appflowy_editor/src/extensions/object_extensions.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:appflowy_editor/src/render/selection/v2/selectable_v2.dart';
import 'package:flutter/material.dart';

extension NodeExtensions on Node {
  RenderBox? get renderBox =>
      key.currentContext?.findRenderObject()?.unwrapOrNull<RenderBox>();

  BuildContext? get context => key.currentContext;
  SelectableMixin? get selectable =>
      key.currentState?.unwrapOrNull<SelectableMixin>();
  SelectableState? get selectableV2 =>
      key.currentState?.unwrapOrNull<SelectableState>();

  bool inSelection(Selection selection) {
    if (selection.start.path <= selection.end.path) {
      return selection.start.path <= path && path <= selection.end.path;
    } else {
      return selection.end.path <= path && path <= selection.start.path;
    }
  }

  Rect get rect {
    if (renderBox != null) {
      final boxOffset = renderBox!.localToGlobal(Offset.zero);
      return boxOffset & renderBox!.size;
    }
    return Rect.zero;
  }

  bool isSelected(EditorState editorState) {
    final currentSelectedNodes =
        editorState.service.selectionService.currentSelectedNodes;
    return currentSelectedNodes.length == 1 &&
        currentSelectedNodes.first == this;
  }
}

extension NodesExtensions<T extends Node> on List<T> {
  List<T> get normalized {
    if (isEmpty) {
      return this;
    }

    if (first.path > last.path) {
      return reversed.toList();
    }

    return this;
  }
}
