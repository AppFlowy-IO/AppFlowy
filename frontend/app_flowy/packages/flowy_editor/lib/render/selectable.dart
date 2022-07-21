import 'package:flutter/material.dart';

///
mixin Selectable<T extends StatefulWidget> on State<T> {
  /// Returns a [Rect] list for overlay.
  /// [start] and [end] are global offsets.
  List<Rect> getOverlayRectsInRange(Offset start, Offset end);
}
