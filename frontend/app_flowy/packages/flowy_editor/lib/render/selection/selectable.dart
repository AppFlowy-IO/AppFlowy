import 'package:flutter/material.dart';

///
mixin Selectable<T extends StatefulWidget> on State<T> {
  /// Returns a [Rect] list for overlay.
  /// [start] and [end] are global offsets.
  /// The return result must be an local offset.
  List<Rect> getSelectionRectsInRange(Offset start, Offset end);

  /// Returns a [Rect] for cursor.
  /// The return result must be an local offset.
  Rect getCursorRect(Offset start);

  /// For [TextNode] only.
  TextSelection? getTextSelection();
}
