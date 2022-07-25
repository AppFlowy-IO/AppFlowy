import 'package:flutter/material.dart';

///
mixin Selectable<T extends StatefulWidget> on State<T> {
  /// Returns a [List] of the [Rect] selection sorrounded by start and end
  ///   in current widget.
  ///
  /// [start] and [end] are the offsets under the global coordinate system.
  ///
  /// The return result must be a [List] of the [Rect]
  ///   under the local coordinate system.
  List<Rect> getSelectionRectsInRange(Offset start, Offset end);

  /// Returns a [Rect] for the offset in current widget.
  ///
  /// [start] is the offset of the global coordination system.
  ///
  /// The return result must be an offset of the local coordinate system.
  Rect getCursorRect(Offset start);

  /// Returns a backward offset of the current offset based on the cause.
  Offset getBackwardOffset(/* Cause */);

  /// Returns a forward offset of the current offset based on the cause.
  Offset getForwardOffset(/* Cause */);

  /// For [TextNode] only.
  ///
  /// Returns a [TextSelection] or [Null].
  ///
  /// Only the widget rendered by [TextNode] need to implement the detail,
  ///   and the rest can return null.
  TextSelection? getCurrentTextSelection();

  /// For [TextNode] only.
  ///
  /// Retruns a [Offset].
  /// Only the widget rendered by [TextNode] need to implement the detail,
  ///   and the rest can return [Offset.zero].
  Offset getOffsetByTextSelection(TextSelection textSelection);
}
