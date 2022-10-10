import 'package:appflowy_editor/src/core/selection/position.dart';
import 'package:appflowy_editor/src/document/selection.dart';
import 'package:appflowy_editor/src/render/selection/selectable.dart';
import 'package:flutter/material.dart';

mixin DefaultSelectable {
  SelectableMixin get forward;

  GlobalKey? get iconKey;

  Offset get baseOffset {
    if (iconKey != null) {
      final renderBox = iconKey!.currentContext?.findRenderObject();
      if (renderBox is RenderBox) {
        return Offset(renderBox.size.width, 0);
      }
    }
    return Offset.zero;
  }

  Position getPositionInOffset(Offset start) =>
      forward.getPositionInOffset(start);

  Rect? getCursorRectInPosition(Position position) =>
      forward.getCursorRectInPosition(position)?.shift(baseOffset);

  List<Rect> getRectsInSelection(Selection selection) => forward
      .getRectsInSelection(selection)
      .map((rect) => rect.shift(baseOffset))
      .toList(growable: false);

  Selection getSelectionInRange(Offset start, Offset end) =>
      forward.getSelectionInRange(start, end);

  Offset localToGlobal(Offset offset) =>
      forward.localToGlobal(offset) - baseOffset;

  Selection? getWorldBoundaryInOffset(Offset offset) =>
      forward.getWorldBoundaryInOffset(offset);

  Position start() => forward.start();

  Position end() => forward.end();
}
