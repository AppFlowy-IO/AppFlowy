import 'package:flutter/material.dart';

///
mixin Selectable<T extends StatefulWidget> on State<T> {
  /// Returns a [Rect] list for overlay.
  /// [start] and [end] are global offsets.
  List<Rect> getSelectionRectsInSelection(Offset start, Offset end);

  /// Returns a [Rect] for cursor.
  Rect getCursorRect(Offset start);

  /// For [TextNode] only.
  TextSelection? getTextSelection();
}

mixin KeyboardEventsRespondable<T extends StatefulWidget> on State<T> {
  KeyEventResult onKeyDown(RawKeyEvent event);
}
