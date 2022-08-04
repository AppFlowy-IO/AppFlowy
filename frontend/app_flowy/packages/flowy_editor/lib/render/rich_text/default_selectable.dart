import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flowy_editor/render/selection/selectable.dart';
import 'package:flutter/material.dart';

mixin DefaultSelectable {
  Selectable get forward;

  Offset get baseOffset;

  Position getPositionInOffset(Offset start) =>
      forward.getPositionInOffset(start);

  Rect getCursorRectInPosition(Position position) =>
      forward.getCursorRectInPosition(position).shift(baseOffset);

  List<Rect> getRectsInSelection(Selection selection) => forward
      .getRectsInSelection(selection)
      .map((rect) => rect.shift(baseOffset))
      .toList(growable: false);

  Selection getSelectionInRange(Offset start, Offset end) =>
      forward.getSelectionInRange(start, end);

  Offset localToGlobal(Offset offset) => forward.localToGlobal(offset);

  Selection? getWorldBoundaryInOffset(Offset offset) =>
      forward.getWorldBoundaryInOffset(offset);

  Position start() => forward.start();

  Position end() => forward.end();
}
