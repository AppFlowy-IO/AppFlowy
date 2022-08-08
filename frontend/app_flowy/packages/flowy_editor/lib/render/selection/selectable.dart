import 'package:flowy_editor/document/position.dart';
import 'package:flowy_editor/document/selection.dart';
import 'package:flutter/material.dart';

///
mixin Selectable<T extends StatefulWidget> on State<T> {
  /// Returns a [List] of the [Rect] selection surrounded by start and end
  ///   in current widget.
  ///
  /// [start] and [end] are the offsets under the global coordinate system.
  ///
  /// The return result must be a [List] of the [Rect]
  ///   under the local coordinate system.
  Selection getSelectionInRange(Offset start, Offset end);

  List<Rect> getRectsInSelection(Selection selection);

  /// Returns a [Rect] for the offset in current widget.
  ///
  /// [start] is the offset of the global coordination system.
  ///
  /// The return result must be an offset of the local coordinate system.
  Position getPositionInOffset(Offset start);
  Selection? getWorldBoundaryInOffset(Offset start) {
    return null;
  }

  Rect? getCursorRectInPosition(Position position) {
    return null;
  }

  Offset localToGlobal(Offset offset);

  Position start();
  Position end();

  /// For [TextNode] only.
  ///
  /// Returns a [TextSelection] or [Null].
  ///
  /// Only the widget rendered by [TextNode] need to implement the detail,
  ///   and the rest can return null.
  TextSelection? getTextSelectionInSelection(Selection selection) => null;
}
